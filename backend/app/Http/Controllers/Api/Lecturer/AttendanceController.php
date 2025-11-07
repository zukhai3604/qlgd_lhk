<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\AttendanceStoreRequest;
use App\Http\Resources\Lecturer\AttendanceRecordResource;
use App\Models\AttendanceRecord;
use App\Models\Schedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use OpenApi\Annotations as OA;

class AttendanceController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/sessions/{id}/attendance",
     *   operationId="lecturerAttendanceShow",
     *   tags={"Lecturer - Điểm danh"},
     *   summary="Xem danh sách điểm danh cho một buổi dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="id",
     *     in="path",
     *     required=true,
     *     @OA\Schema(type="integer", example=345)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách điểm danh",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="student_id", type="integer", example=1001),
     *           @OA\Property(property="student_name", type="string", example="Trần Thị B"),
     *           @OA\Property(property="status", type="string", example="PRESENT"),
     *           @OA\Property(property="note", type="string", nullable=true, example="Nghỉ có phép"),
     *           @OA\Property(property="marked_at", type="string", format="date-time", example="2025-10-21T07:00:00+07:00")
     *         )
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền truy cập",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy buổi dạy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function show(Request $request, int $id)
    {
        $schedule = Schedule::with('assignment')->find($id);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $records = AttendanceRecord::with('student')
            ->where('schedule_id', $schedule->id)
            ->get();

        return AttendanceRecordResource::collection($records);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/sessions/{id}/attendance",
     *   operationId="lecturerAttendanceStore",
     *   tags={"Lecturer - Điểm danh"},
     *   summary="Tạo hoặc cập nhật điểm danh",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="id",
     *     in="path",
     *     required=true,
     *     @OA\Schema(type="integer", example=345)
     *   ),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"records"},
     *       @OA\Property(
     *         property="records",
     *         type="array",
     *         @OA\Items(ref="#/components/schemas/AttendancePayloadItem")
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Lưu điểm danh thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="message", type="string", example="Đã lưu điểm danh"),
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="student_id", type="integer"),
     *           @OA\Property(property="status", type="string"),
     *           @OA\Property(property="note", type="string", nullable=true)
     *         )
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền truy cập",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy buổi dạy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Dữ liệu không hợp lệ",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function store(AttendanceStoreRequest $request, int $id)
    {
        $schedule = Schedule::with(['assignment.classUnit'])->find($id);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $data = $request->validated();

        DB::transaction(function () use ($data, $schedule, $request) {
            foreach ($data['records'] as $record) {
                AttendanceRecord::updateOrCreate(
                    ['schedule_id' => $schedule->id, 'student_id' => $record['student_id']],
                    [
                        'status' => $record['status'],
                        'note' => $record['note'] ?? null,
                        'marked_by' => $request->user()->id,
                        'marked_at' => now(),
                    ]
                );
            }
        });

        $records = AttendanceRecord::with('student')
            ->where('schedule_id', $schedule->id)
            ->get();

        return AttendanceRecordResource::collection($records)
            ->additional(['message' => 'Đã lưu điểm danh']);
    }
}
