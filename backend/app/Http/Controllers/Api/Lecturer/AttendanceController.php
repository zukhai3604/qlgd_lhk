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
        try {
            // Eager load đầy đủ để tránh N+1 query
            $schedule = Schedule::with([
                'assignment.classUnit',
                'assignment.lecturer'
            ])->find($id);
            
            if (!$schedule) {
                return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
            }

            $user = $request->user();
            if (!$user) {
                return response()->json(['message' => 'Chưa đăng nhập'], 401);
            }

            $lecturer = $user->lecturer;
            if (!$lecturer) {
                return response()->json(['message' => 'Không tìm thấy thông tin giảng viên'], 403);
            }

            // Kiểm tra assignment tồn tại
            if (!$schedule->assignment) {
                try {
                    \Log::error('Attendance API: Schedule missing assignment', ['schedule_id' => $id]);
                } catch (\Exception $e) {
                    // Ignore logging errors
                }
                return response()->json(['message' => 'Buổi dạy không có phân công'], 404);
            }

            if ($schedule->assignment->lecturer_id !== $lecturer->id) {
                return response()->json(['message' => 'Không có quyền truy cập buổi dạy này'], 403);
            }

            // Kiểm tra classUnit tồn tại
            if (!$schedule->assignment->classUnit) {
                try {
                    \Log::error('Attendance API: Assignment missing classUnit', [
                        'schedule_id' => $id,
                        'assignment_id' => $schedule->assignment->id
                    ]);
                } catch (\Exception $e) {
                    // Ignore logging errors
                }
                return response()->json(['message' => 'Phân công không có lớp học'], 404);
            }

            $classUnit = $schedule->assignment->classUnit;
            $classUnitId = $classUnit->id;

            // Query students với error handling
            try {
                $allStudents = $classUnit->students()->orderBy('code')->get();
            } catch (\Exception $e) {
                try {
                    \Log::error('Attendance API: Error loading students', [
                        'schedule_id' => $id,
                        'class_unit_id' => $classUnitId,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                } catch (\Exception $logError) {
                    // Ignore logging errors
                }
                return response()->json(['message' => 'Lỗi khi tải danh sách sinh viên: ' . $e->getMessage()], 500);
            }

            // Debug logging - wrap trong try-catch để tránh crash nếu không thể ghi log
            try {
                \Log::info('Attendance API Debug', [
                    'schedule_id' => $schedule->id,
                    'class_unit_id' => $classUnitId,
                    'class_unit_code' => $classUnit->code,
                    'students_count' => $allStudents->count(),
                ]);
            } catch (\Exception $logError) {
                // Ignore logging errors - không làm crash API
            }

            // Lấy các attendance records đã có với error handling
            try {
                $existingRecords = AttendanceRecord::with('student')
                    ->where('schedule_id', $schedule->id)
                    ->get()
                    ->keyBy('student_id');
            } catch (\Exception $e) {
                try {
                    \Log::error('Attendance API: Error loading attendance records', [
                        'schedule_id' => $schedule->id,
                        'error' => $e->getMessage()
                    ]);
                } catch (\Exception $logError) {
                    // Ignore logging errors
                }
                // Tiếp tục với empty records nếu có lỗi
                $existingRecords = collect();
            }

            // Tạo danh sách kết hợp với null safety và giới hạn memory
            $result = collect();
            
            try {
                // Chuyển đổi sang array ngay để tránh memory issue với collection lớn
                $result = $allStudents->map(function ($student) use ($existingRecords, $schedule) {
                    if (!$student) {
                        return null;
                    }

                    $record = $existingRecords->get($student->id);
                    
                    if ($record) {
                        // Đã có điểm danh
                        return [
                            'id' => $record->id ?? null,
                            'schedule_id' => $schedule->id,
                            'student' => [
                                'id' => $student->id ?? null,
                                'code' => $student->code ?? null,
                                'name' => $student->full_name ?? null,
                            ],
                            'status' => $record->status ?? null,
                            'note' => $record->note ?? null,
                            'marked_by' => $record->marked_by ?? null,
                            'marked_at' => optional($record->marked_at)->toDateTimeString(),
                        ];
                    } else {
                        // Chưa điểm danh
                        return [
                            'id' => null,
                            'schedule_id' => $schedule->id,
                            'student' => [
                                'id' => $student->id ?? null,
                                'code' => $student->code ?? null,
                                'name' => $student->full_name ?? null,
                            ],
                            'status' => null,
                            'note' => null,
                            'marked_by' => null,
                            'marked_at' => null,
                        ];
                    }
                })->filter()->values()->all(); // Convert to array ngay
            } catch (\Exception $e) {
                try {
                    \Log::error('Attendance API: Error in map function', [
                        'schedule_id' => $schedule->id,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                } catch (\Exception $logError) {
                    // Ignore logging errors
                }
                // Tiếp tục với empty result nếu có lỗi trong map
                $result = [];
            }

            return response()->json(['data' => $result], 200, [
                'Content-Type' => 'application/json; charset=utf-8',
                'X-Content-Type-Options' => 'nosniff'
            ]);
            
        } catch (\Throwable $e) {
            try {
                \Log::error('Attendance API Error', [
                    'schedule_id' => $id ?? null,
                    'error' => $e->getMessage(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                    'trace' => $e->getTraceAsString(),
                ]);
            } catch (\Exception $logError) {
                // Ignore logging errors - đảm bảo vẫn trả về JSON response
            }
            
            // Đảm bảo luôn trả về JSON response, không bao giờ để exception handler render HTML
            return response()->json([
                'message' => 'Lỗi hệ thống khi xử lý yêu cầu điểm danh',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500, [
                'Content-Type' => 'application/json; charset=utf-8'
            ]);
        }
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

        // Reload schedule với relationships để lấy danh sách đầy đủ
        $schedule->load(['assignment.classUnit']);
        $classUnit = $schedule->assignment->classUnit;
        $allStudents = $classUnit->students()->orderBy('code')->get();

        // Lấy các attendance records đã có sau khi lưu
        $existingRecords = AttendanceRecord::with('student')
            ->where('schedule_id', $schedule->id)
            ->get()
            ->keyBy('student_id');

        // Tạo danh sách kết hợp: tất cả sinh viên trong lớp + attendance records
        $result = $allStudents->map(function ($student) use ($existingRecords, $schedule) {
            $record = $existingRecords->get($student->id);
            
            if ($record) {
                return [
                    'id' => $record->id,
                    'schedule_id' => $schedule->id,
                    'student' => [
                        'id' => $student->id,
                        'code' => $student->code ?? null,
                        'name' => $student->full_name ?? null,
                    ],
                    'status' => $record->status,
                    'note' => $record->note,
                    'marked_by' => $record->marked_by,
                    'marked_at' => optional($record->marked_at)->toDateTimeString(),
                ];
            } else {
                return [
                    'id' => null,
                    'schedule_id' => $schedule->id,
                    'student' => [
                        'id' => $student->id,
                        'code' => $student->code ?? null,
                        'name' => $student->full_name ?? null,
                    ],
                    'status' => null,
                    'note' => null,
                    'marked_by' => null,
                    'marked_at' => null,
                ];
            }
        });

        return response()->json([
            'message' => 'Đã lưu điểm danh',
            'data' => $result->values()
        ]);
    }
}
