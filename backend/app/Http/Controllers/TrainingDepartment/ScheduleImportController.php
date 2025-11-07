<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use App\Models\ClassUnit;
use App\Models\Room;
use App\Models\Schedule;
use App\Models\Subject;
use App\Models\Timeslot;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use OpenApi\Annotations as OA;

/**
 * @OA\Tag(
 *   name="Training Department - Schedule Import",
 *   description="Nhập file để sinh lịch giảng dạy tự động (vai trò DAO_TAO)"
 * )
 */
class ScheduleImportController extends Controller
{
    /**
     * CSV Columns (header required):
     * subject_code,class_unit_code,date,timeslot_code,room_code,lecturer_email
     * - date: YYYY-MM-DD
     * - timeslot_code: mã ca trong bảng timeslots (ví dụ: CA1, CA2)
     * - room_code: mã phòng (nếu bỏ trống sẽ để null)
     * - lecturer_email: tùy chọn, để chọn đúng assignment theo giảng viên
     */

    /**
     * @OA\Get(
     *   path="/api/training_department/schedules/import/template",
     *   operationId="trainingScheduleImportTemplate",
     *   tags={"Training Department - Schedule Import"},
     *   summary="Tải file CSV mẫu để nhập lịch",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="CSV template", @OA\MediaType(mediaType="text/csv"))
     * )
     */
    public function template()
    {
        $csv = implode("\n", [
            'subject_code,class_unit_code,date,timeslot_code,room_code,lecturer_email',
            'CT101,63TH1,2025-11-10,CA1,A101,giangvien1@tlu.edu.vn',
            'CT101,63TH1,2025-11-12,CA2,A102,giangvien1@tlu.edu.vn',
        ]);
        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="schedule_import_template.csv"',
        ]);
    }

    /**
     * @OA\Post(
     *   path="/api/training_department/schedules/import",
     *   operationId="trainingScheduleImport",
     *   tags={"Training Department - Schedule Import"},
     *   summary="Nhập file CSV để sinh lịch giảng dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\MediaType(
     *       mediaType="multipart/form-data",
     *       @OA\Schema(
     *         required={"file"},
     *         @OA\Property(property="file", type="string", format="binary", description="File CSV với header chuẩn"),
     *         @OA\Property(property="dry_run", type="boolean", description="Chạy thử, không ghi DB", example=false)
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Kết quả import",
     *     @OA\JsonContent(
     *       @OA\Property(property="summary", type="object",
     *         @OA\Property(property="total", type="integer"),
     *         @OA\Property(property="created", type="integer"),
     *         @OA\Property(property="updated", type="integer"),
     *         @OA\Property(property="skipped", type="integer"),
     *         @OA\Property(property="errors", type="integer")
     *       ),
     *       @OA\Property(property="errors", type="array", @OA\Items(type="object"))
     *     )
     *   )
     * )
     */
    public function import(Request $request)
    {
        $v = Validator::make($request->all(), [
            'file' => ['required','file'],
            'dry_run' => ['nullable','boolean'],
        ]);
        if ($v->fails()) {
            return response()->json(['message'=>'Invalid request','errors'=>$v->errors()], 422);
        }

        $dryRun = (bool) $request->boolean('dry_run');
        $file = $request->file('file');
        $path = $file->getRealPath();
        if (!$path) {
            return response()->json(['message'=>'Không đọc được file'], 422);
        }

        $handle = fopen($path, 'r');
        if (!$handle) {
            return response()->json(['message'=>'Không mở được file'], 422);
        }

        $headers = fgetcsv($handle);
        if (!$headers) {
            fclose($handle);
            return response()->json(['message'=>'File CSV trống hoặc thiếu header'], 422);
        }
        // Normalize headers
        $headers = array_map(fn($h) => strtolower(trim((string)$h)), $headers);
        $required = ['subject_code','class_unit_code','date','timeslot_code'];
        foreach ($required as $col) {
            if (!in_array($col, $headers, true)) {
                fclose($handle);
                return response()->json(['message'=>"Thiếu cột bắt buộc: $col"], 422);
            }
        }

        $idx = array_flip($headers);
        $total=0; $created=0; $updated=0; $skipped=0; $errorsCount=0; $errors=[];

        DB::beginTransaction();
        try {
            while (($row = fgetcsv($handle)) !== false) {
                $total++;
                $subjectCode     = self::col($row, $idx, 'subject_code');
                $classUnitCode   = self::col($row, $idx, 'class_unit_code');
                $date            = self::col($row, $idx, 'date');
                $timeslotCode    = self::col($row, $idx, 'timeslot_code');
                $roomCode        = self::col($row, $idx, 'room_code');
                $lecturerEmail   = self::col($row, $idx, 'lecturer_email');

                // Basic validation per row
                if (!$subjectCode || !$classUnitCode || !$date || !$timeslotCode) {
                    $errorsCount++; $errors[] = ['row'=>$total+1,'message'=>'Thiếu dữ liệu bắt buộc'];
                    $skipped++; continue;
                }

                $subject = Subject::where('code',$subjectCode)->first();
                $class   = ClassUnit::where('code',$classUnitCode)->first();
                $slot    = Timeslot::where('code',$timeslotCode)->first();
                $room    = $roomCode ? Room::where('code',$roomCode)->first() : null;
                if (!$subject || !$class || !$slot) {
                    $parts=[];
                    if(!$subject) $parts[]='subject_code';
                    if(!$class)   $parts[]='class_unit_code';
                    if(!$slot)    $parts[]='timeslot_code';
                    $errorsCount++; $errors[] = ['row'=>$total+1,'message'=>'Không tìm thấy: '.implode(', ',$parts)];
                    $skipped++; continue;
                }

                // Find assignment for subject & class (and lecturer if provided)
                $assignmentQ = Assignment::where('subject_id',$subject->id)
                    ->where('class_unit_id',$class->id);
                if ($lecturerEmail) {
                    $user = User::where('email',$lecturerEmail)->first();
                    if ($user && $user->lecturer) {
                        $assignmentQ->where('lecturer_id', $user->lecturer->id);
                    }
                }
                $assignment = $assignmentQ->first();
                if (!$assignment) {
                    $errorsCount++; $errors[] = ['row'=>$total+1,'message'=>'Không xác định được assignment (môn+lớp+giảng viên)'];
                    $skipped++; continue;
                }

                // Upsert schedule by unique key (assignment_id + date + timeslot)
                $existing = Schedule::where('assignment_id',$assignment->id)
                    ->whereDate('session_date',$date)
                    ->where('timeslot_id',$slot->id)
                    ->first();

                if ($dryRun) {
                    // Do nothing, just count as would be created/updated
                    if ($existing) { $updated++; } else { $created++; }
                    continue;
                }

                if ($existing) {
                    $existing->room_id = $room?->id;
                    $existing->status  = $existing->status ?: 'PLANNED';
                    $existing->save();
                    $updated++;
                } else {
                    Schedule::create([
                        'assignment_id' => $assignment->id,
                        'session_date'  => $date,
                        'timeslot_id'   => $slot->id,
                        'room_id'       => $room?->id,
                        'status'        => 'PLANNED',
                    ]);
                    $created++;
                }
            }

            fclose($handle);
            if ($dryRun) {
                DB::rollBack();
            } else {
                DB::commit();
            }

            return response()->json([
                'summary' => [
                    'total'   => $total,
                    'created' => $created,
                    'updated' => $updated,
                    'skipped' => $skipped,
                    'errors'  => $errorsCount,
                ],
                'errors' => $errors,
            ]);
        } catch (\Throwable $e) {
            fclose($handle);
            DB::rollBack();
            return response()->json(['message'=>'Lỗi xử lý file','error'=>$e->getMessage()], 500);
        }
    }

    private static function col(array $row, array $idx, string $key): ?string
    {
        if (!array_key_exists($key, $idx)) return null;
        $v = $row[$idx[$key]] ?? null;
        $s = is_string($v) ? trim($v) : (string)$v;
        return $s === '' ? null : $s;
    }
}
