<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use App\Models\Notification;
use App\Models\Schedule;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;
use App\Http\Resources\Lecturer\LeaveRequestResource;
use App\Http\Resources\Lecturer\MakeupRequestResource;

/**
 * @OA\Tag(
 *   name="Training Department - Approvals",
 *   description="Phê duyệt đơn của phòng Đào tạo (vai trò DAO_TAO)"
 * )
 */
class ApprovalController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/training_department/approvals/leave/pending",
     *   operationId="trainingPendingLeaves",
     *   tags={"Training Department - Approvals"},
     *   summary="Danh sách đơn nghỉ đang chờ duyệt",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phân trang",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(ref="#/components/schemas/LeaveRequestResource")
     *       ),
     *       @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
     *     )
     *   )
     * )
     */
    public function listPendingLeaves(Request $request)
    {
        $items = LeaveRequest::query()
            ->with([
                'schedule.assignment.subject',
                'schedule.assignment.classUnit',
                'schedule.timeslot',
                'schedule.room',
                'lecturer.user',
                'lecturer.department.faculty',
            ])
            ->where('status', 'PENDING')
            ->orderByDesc('id')
            ->paginate(20);

        return LeaveRequestResource::collection($items)
            ->additional(['meta' => ['total' => $items->total()]]);
    }

    /**
     * @OA\Get(
     *   path="/api/training_department/approvals/makeup/pending",
     *   operationId="trainingPendingMakeups",
     *   tags={"Training Department - Approvals"},
     *   summary="Danh sách đề xuất dạy bù đang chờ duyệt",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phân trang",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(ref="#/components/schemas/MakeupRequestResource")
     *       ),
     *       @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
     *     )
     *   )
     * )
     */
    public function listPendingMakeups(Request $request)
    {
        $items = MakeupRequest::query()
            ->with([
                'leave.schedule.assignment.subject',
                'leave.schedule.assignment.classUnit',
                'leave.schedule.timeslot',
                'leave.schedule.room',
                'leave.lecturer.user',
                'leave.lecturer.department.faculty',
                'timeslot',
                'room',
            ])
            ->where('status', 'PENDING')
            ->orderByDesc('id')
            ->paginate(20);

        return MakeupRequestResource::collection($items)
            ->additional(['meta' => ['total' => $items->total()]]);
    }
     /**
      * @OA\Post(
      *   path="/api/training_department/approvals/leave/{leave}",
      *   operationId="trainingApproveLeave",
      *   tags={"Training Department - Approvals"},
      *   summary="Phê duyệt / từ chối đơn nghỉ dạy (gộp các tiết cùng ngày/cùng ca)",
      *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="leave", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"status"},
     *       @OA\Property(property="status", type="string", example="APPROVED", description="APPROVED hoặc REJECTED"),
    *       @OA\Property(property="note", type="string", nullable=true, example="Đã sắp xếp giảng viên thay thế")
     *     )
     *   ),
      *   @OA\Response(
      *     response=200,
      *     description="Cập nhật trạng thái đề xuất dạy bù. Hệ thống sẽ tự động áp dụng cho toàn bộ các tiết dạy bù cùng ngày và cùng ca (timeslot) của giảng viên (nếu đều đang PENDING)",
      *     @OA\JsonContent(
      *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
      *     )
      *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function approveLeave(Request $request, LeaveRequest $leave)
    {
        // Chỉ cho phép xử lý đơn PENDING (ít nhất đơn nền tảng phải PENDING)
        if ($leave->status !== 'PENDING') {
            return response()->json([
                'message' => 'Chỉ xử lý đơn ở trạng thái PENDING'
            ], 422);
        }

        // Validate đầu vào
        $data = $request->validate([
            'status' => ['required', 'string', 'in:APPROVED,REJECTED'],
            'note'   => ['nullable', 'string', 'max:255'],
        ]);

        $user = $request->user();

        // Xác định nhóm gộp: cùng giảng viên + cùng ngày học + các tiết liền kề + cùng phân công (assignment)
        $leave->load(['schedule.assignment.subject', 'schedule.assignment.classUnit', 'schedule.timeslot', 'schedule.room', 'lecturer.user', 'lecturer.department']);
        
        $schedule = $leave->schedule;
        if (!$schedule) {
            return response()->json([
                'message' => 'Không tìm thấy lịch học liên kết với đơn nghỉ này'
            ], 422);
        }

        $timeslotId  = $schedule->timeslot_id;
        $sessionDate = $schedule->session_date?->format('Y-m-d');
        $assignmentId = $schedule->assignment_id;

        // QUAN TRỌNG: Chỉ gộp các tiết THỰC SỰ LIỀN KỀ NHAU
        $siblings = collect([$leave]);
        if ($timeslotId && $sessionDate && $assignmentId) {
            // Bước 1: Lấy tất cả đơn nghỉ PENDING cùng giảng viên, cùng ngày, cùng assignment
            $allPendingLeaves = LeaveRequest::query()
                ->with(['schedule.timeslot', 'schedule.assignment', 'lecturer'])
                ->where('lecturer_id', $leave->lecturer_id)
                ->where('status', 'PENDING')
                ->whereHas('schedule', function ($q) use ($sessionDate, $assignmentId) {
                    $q->where('assignment_id', $assignmentId)
                      ->whereDate('session_date', $sessionDate);
                })
                ->get();

            // Bước 2: Tìm nhóm các timeslot LIỀN KỀ chứa timeslot hiện tại
            $siblings = $this->findAdjacentLeaveRequests($allPendingLeaves, $timeslotId);
            
            // Bước 3: LOG để debug (có thể xóa sau khi test)
            \Log::info('Adjacent leave requests found', [
                'pivot_timeslot_id' => $timeslotId,
                'all_pending_count' => $allPendingLeaves->count(),
                'adjacent_count' => $siblings->count(),
                'adjacent_timeslot_ids' => $siblings->pluck('schedule.timeslot_id')->toArray(),
            ]);
        }

        $affected = 0;

        \DB::transaction(function () use ($siblings, $data, $user, &$affected) {
            foreach ($siblings as $lr) {
                // Cập nhật từng đơn trong nhóm (chỉ các đơn đang PENDING do truy vấn đã lọc)
                $lr->status = $data['status'];
                $lr->approved_by = $user->id;
                $lr->approved_at = now();
                if (array_key_exists('note', $data)) {
                    $lr->note = $data['note'];
                }
                $lr->save();
                $affected++;

                // Nếu duyệt: hủy buổi học gốc tương ứng
                if ($lr->status === 'APPROVED') {
                    try {
                        $scheduleToCancel = $lr->schedule; // có thể đã eager loaded
                        if ($scheduleToCancel) {
                            // Chỉ cancel nếu chưa bị cancel hoặc chưa hoàn thành
                            if (!in_array($scheduleToCancel->status, ['CANCELED', 'DONE', 'COMPLETED'])) {
                                $scheduleToCancel->status = 'CANCELED';
                                $scheduleToCancel->note = ($scheduleToCancel->note ?? '') . ' [Đã duyệt đơn nghỉ]';
                                $scheduleToCancel->save();
                            }
                        }
                    } catch (\Throwable $e) {
                        // bỏ qua lỗi trên 1 phần tử, tiếp tục phần còn lại
                        \Log::warning("Failed to cancel schedule for leave request {$lr->id}: " . $e->getMessage());
                    }
                }
            }
        });

        // Gửi thông báo 1 lần cho giảng viên, nêu rõ số tiết được xử lý
        try {
            $toUserId = $leave->lecturer?->user_id; // user id của giảng viên
            if ($toUserId) {
                $title = ($data['status'] === 'APPROVED')
                    ? 'Đơn nghỉ đã được duyệt'
                    : 'Đơn nghỉ bị từ chối';
                
                $bodyParts = [];
                if ($affected > 1) {
                    $bodyParts[] = "Số tiết được xử lý: {$affected}";
                }
                if ($sessionDate) {
                    $bodyParts[] = "Ngày: {$sessionDate}";
                }
                if (!empty($data['note'])) {
                    $bodyParts[] = "Ghi chú: {$data['note']}";
                }
                $body = implode(' | ', $bodyParts);

                Notification::create([
                    'from_user_id' => $user->id,
                    'to_user_id'   => $toUserId,
                    'title'        => $title,
                    'body'         => $body,
                    'type'         => 'LEAVE_RESPONSE',
                    'status'       => 'UNREAD',
                    'created_at'   => now(),
                ]);
            }
        } catch (\Throwable $e) {
            \Log::warning("Failed to send leave approval notification: " . $e->getMessage());
        }

        // Trả về bản ghi nền tảng sau khi cập nhật
        $leave->refresh();

        return response()->json([
            'data' => \App\Http\Resources\Lecturer\LeaveRequestResource::make($leave),
            'meta' => [
                'affected_count' => $affected,
                'group_by' => [
                    'timeslot_id'  => $timeslotId,
                    'session_date' => $sessionDate,
                ],
            ],
        ]);
    }

     /**
      * @OA\Post(
      *   path="/api/training_department/approvals/makeup/{makeup}",
      *   operationId="trainingApproveMakeup",
      *   tags={"Training Department - Approvals"},
      *   summary="Phê duyệt / từ chối đề xuất dạy bù (gộp các tiết cùng ngày dạy bù/cùng ca)",
      *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="makeup", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"status"},
     *       @OA\Property(property="status", type="string", example="APPROVED", description="APPROVED hoặc REJECTED"),
     *       @OA\Property(property="note", type="string", nullable=true, example="Đã sắp xếp phòng phù hợp")
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
    *     description="Cập nhật trạng thái đề xuất dạy bù. Hệ thống sẽ tự động áp dụng cho toàn bộ các tiết dạy bù cùng ngày và cùng phân công (nếu đều đang PENDING)",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function approveMakeup(Request $request, MakeupRequest $makeup)
    {
        // Chỉ xử lý khi PENDING (ít nhất bản ghi nền tảng)
        if ($makeup->status !== 'PENDING') {
            return response()->json([
                'message' => 'Chỉ xử lý đề xuất ở trạng thái PENDING'
            ], 422);
        }

        $data = $request->validate([
            'status' => ['required', 'string', 'in:APPROVED,REJECTED'],
            'note'   => ['nullable', 'string', 'max:255'],
        ]);

        $user = $request->user();

        // Xác định nhóm gộp: cùng giảng viên + cùng ngày dạy bù + các tiết liền kề + cùng assignment gốc
        $makeup->load(['leave.schedule.assignment', 'leave.lecturer', 'timeslot']);
        
        $leave = $makeup->leave;
        if (!$leave) {
            return response()->json([
                'message' => 'Không tìm thấy đơn nghỉ liên kết với đề xuất dạy bù này'
            ], 422);
        }

        $origSchedule = $leave->schedule;
        if (!$origSchedule) {
            return response()->json([
                'message' => 'Không tìm thấy lịch học gốc liên kết với đơn nghỉ này'
            ], 422);
        }

        $lecturerId = $leave->lecturer_id;
        $timeslotId = $makeup->timeslot_id;
        $suggested  = $makeup->suggested_date?->format('Y-m-d');
        $assignmentId = $origSchedule->assignment_id;

        $siblings = collect([$makeup]);
        if ($lecturerId && $timeslotId && $suggested && $assignmentId) {
            // Bước 1: Lấy tất cả đề xuất dạy bù PENDING cùng giảng viên, cùng ngày đề xuất, cùng assignment gốc
            $allPendingMakeups = MakeupRequest::query()
                ->with(['leave.schedule', 'timeslot'])
                ->where('status', 'PENDING')
                ->whereDate('suggested_date', $suggested)
                ->whereHas('leave', function ($q) use ($lecturerId, $assignmentId) {
                    $q->where('lecturer_id', $lecturerId)
                      ->whereHas('schedule', function ($sq) use ($assignmentId) {
                          $sq->where('assignment_id', $assignmentId);
                      });
                })
                ->get();

            // Bước 2: Tìm nhóm các timeslot liền kề chứa timeslot hiện tại
            $siblings = $this->findAdjacentMakeupRequests($allPendingMakeups, $timeslotId);
        }

        $affected = 0;

        \DB::transaction(function () use ($siblings, $data, $user, &$affected) {
            foreach ($siblings as $mk) {
                // Cập nhật trạng thái quyết định
                $mk->status = $data['status'];
                $mk->decided_by = $user->id;
                $mk->decided_at = now();
                if (array_key_exists('note', $data)) {
                    $mk->note = $data['note'];
                }
                $mk->save();
                $affected++;

                // Nếu APPROVED: tạo/lên lịch các buổi dạy bù tương ứng
                if ($mk->status === 'APPROVED') {
                    try {
                        $leaveReq = $mk->leave;
                        $origSched = $leaveReq?->schedule;
                        if ($origSched && $mk->suggested_date) {
                            $assignmentId = $origSched->assignment_id;
                            $makeupDate = $mk->suggested_date->format('Y-m-d');
                            
                            // Kiểm tra xem đã có lịch dạy bù này chưa
                            $existing = Schedule::where('assignment_id', $assignmentId)
                                ->where('session_date', $makeupDate)
                                ->where('timeslot_id', $mk->timeslot_id)
                                ->first();
                            
                            if ($existing) {
                                // Cập nhật lịch hiện có
                                $existing->update([
                                    'room_id'      => $mk->room_id,
                                    'status'       => 'MAKEUP_PLANNED',
                                    'makeup_of_id' => $origSched->id,
                                    'note'         => ($existing->note ?? '') . ' [Dạy bù được duyệt]',
                                ]);
                            } else {
                                // Tạo lịch mới
                                Schedule::create([
                                    'assignment_id' => $assignmentId,
                                    'session_date'  => $makeupDate,
                                    'timeslot_id'   => $mk->timeslot_id,
                                    'room_id'       => $mk->room_id,
                                    'status'        => 'MAKEUP_PLANNED',
                                    'makeup_of_id'  => $origSched->id,
                                    'note'          => $mk->note ?? 'Buổi dạy bù',
                                ]);
                            }
                        }
                    } catch (\Throwable $e) {
                        // bỏ qua lỗi từng phần tử, log để debug
                        \Log::warning("Failed to create makeup schedule for makeup request {$mk->id}: " . $e->getMessage());
                    }
                }
            }
        });

        // Gửi thông báo 1 lần tới giảng viên
        try {
            $toUserId = $makeup->leave?->lecturer?->user_id;
            if ($toUserId) {
                $title = ($data['status'] === 'APPROVED')
                    ? 'Đề xuất dạy bù đã được duyệt'
                    : 'Đề xuất dạy bù bị từ chối';
                
                $bodyParts = [];
                if ($affected > 1) {
                    $bodyParts[] = "Số tiết được xử lý: {$affected}";
                }
                if ($suggested) {
                    $bodyParts[] = "Ngày dạy bù: {$suggested}";
                }
                if (!empty($data['note'])) {
                    $bodyParts[] = "Ghi chú: {$data['note']}";
                }
                $body = implode(' | ', $bodyParts);

                Notification::create([
                    'from_user_id' => $user->id,
                    'to_user_id'   => $toUserId,
                    'title'        => $title,
                    'body'         => $body,
                    'type'         => 'MAKEUP_RESPONSE',
                    'status'       => 'UNREAD',
                    'created_at'   => now(),
                ]);
            }
        } catch (\Throwable $e) {
            \Log::warning("Failed to send makeup approval notification: " . $e->getMessage());
        }

        // Trả về bản ghi nền tảng sau khi cập nhật
        $makeup->refresh();
        return response()->json([
            'data' => \App\Http\Resources\Lecturer\MakeupRequestResource::make($makeup),
            'meta' => [
                'affected_count' => $affected,
                'group_by' => [
                    'timeslot_id'    => $timeslotId ?? null,
                    'suggested_date' => $suggested ?? null,
                ],
            ],
        ]);
    }

    /**
     * Tìm các đơn nghỉ có timeslot THỰC SỰ LIỀN KỀ với timeslot đã cho
     * Logic: Timeslot có code dạng T2_CA1, T2_CA2, T2_CA3...
     * Các tiết liền kề là các tiết có số thứ tự liên tiếp KHÔNG GIÁN ĐOẠN
     * 
     * VD: CA1-CA2-CA3 là liền kề
     * KHÔNG gộp: CA1-CA3 (thiếu CA2 ở giữa)
     * 
     * @param \Illuminate\Support\Collection $leaves - Danh sách các đơn nghỉ cùng ngày/cùng assignment
     * @param int $pivotTimeslotId - ID của timeslot trung tâm
     * @return \Illuminate\Support\Collection
     */
    private function findAdjacentLeaveRequests($leaves, $pivotTimeslotId)
    {
        if ($leaves->isEmpty()) {
            return collect([]);
        }

        // Map các đơn nghỉ theo timeslot_id để tra cứu nhanh
        $leaveByTimeslotId = $leaves->keyBy('schedule.timeslot_id');
        
        if (!$leaveByTimeslotId->has($pivotTimeslotId)) {
            return collect([]);
        }

        $pivotLeave = $leaveByTimeslotId->get($pivotTimeslotId);
        if (!$pivotLeave->schedule) {
            return collect([$pivotLeave]);
        }

        $assignmentId = $pivotLeave->schedule->assignment_id;
        $sessionDate = $pivotLeave->schedule->session_date->format('Y-m-d');

        // Lấy TẤT CẢ schedules của assignment trong ngày
        $allSchedulesOfDay = \App\Models\Schedule::query()
            ->with('timeslot')
            ->where('assignment_id', $assignmentId)
            ->whereDate('session_date', $sessionDate)
            ->get();

        if ($allSchedulesOfDay->isEmpty()) {
            return collect([$pivotLeave]);
        }

        // Parse pivot timeslot code
        $pivotTimeslot = $allSchedulesOfDay->firstWhere('timeslot_id', $pivotTimeslotId)?->timeslot;
        if (!$pivotTimeslot || !preg_match('/^(.+?)(\d+)$/', $pivotTimeslot->code, $matches)) {
            return collect([$pivotLeave]);
        }

        $prefix = $matches[1]; // "T2_CA"
        $pivotNumber = (int)$matches[2]; // 3

        // Map schedule theo số thứ tự timeslot
        $scheduleByNumber = [];
        foreach ($allSchedulesOfDay as $sched) {
            if ($sched->timeslot && preg_match('/^(.+?)(\d+)$/', $sched->timeslot->code, $m) && $m[1] === $prefix) {
                $num = (int)$m[2];
                $scheduleByNumber[$num] = $sched;
            }
        }

        // Tìm dãy LIÊN TỤC (backward + forward)
        $adjacentNumbers = [$pivotNumber];
        
        // Backward: Dừng NGAY khi thiếu schedule hoặc thiếu leave request
        $currentNumber = $pivotNumber - 1;
        while ($currentNumber > 0) {
            // Kiểm tra schedule tồn tại
            if (!isset($scheduleByNumber[$currentNumber])) {
                break; // Không có schedule -> DỪNG
            }
            
            // Kiểm tra leave request tồn tại
            $timeslotId = $scheduleByNumber[$currentNumber]->timeslot_id;
            if (!$leaveByTimeslotId->has($timeslotId)) {
                break; // Không có đơn nghỉ -> DỪNG
            }
            
            array_unshift($adjacentNumbers, $currentNumber);
            $currentNumber--;
        }

        // Forward: Dừng NGAY khi thiếu schedule hoặc thiếu leave request
        $currentNumber = $pivotNumber + 1;
        while (true) {
            // Kiểm tra schedule tồn tại
            if (!isset($scheduleByNumber[$currentNumber])) {
                break; // Không có schedule -> DỪNG
            }
            
            // Kiểm tra leave request tồn tại
            $timeslotId = $scheduleByNumber[$currentNumber]->timeslot_id;
            if (!$leaveByTimeslotId->has($timeslotId)) {
                break; // Không có đơn nghỉ -> DỪNG
            }
            
            $adjacentNumbers[] = $currentNumber;
            $currentNumber++;
        }

        // Lấy danh sách timeslot IDs từ các số liền kề
        $adjacentTimeslotIds = [];
        foreach ($adjacentNumbers as $num) {
            if (isset($scheduleByNumber[$num])) {
                $adjacentTimeslotIds[] = $scheduleByNumber[$num]->timeslot_id;
            }
        }

        // Log để debug
        \Log::debug('Adjacent leave grouping', [
            'pivot_code' => $pivotTimeslot->code,
            'pivot_number' => $pivotNumber,
            'adjacent_numbers' => $adjacentNumbers,
            'adjacent_timeslot_ids' => $adjacentTimeslotIds,
        ]);

        // Trả về các đơn nghỉ có timeslot trong dãy liền kề
        return $leaves->filter(fn($leave) => in_array($leave->schedule?->timeslot_id, $adjacentTimeslotIds));
    }

    /**
     * Tìm các đề xuất dạy bù có timeslot THỰC SỰ LIỀN KỀ với timeslot đã cho
     * 
     * @param \Illuminate\Support\Collection $makeups - Danh sách các đề xuất dạy bù
     * @param int $pivotTimeslotId - ID của timeslot trung tâm
     * @return \Illuminate\Support\Collection
     */
    private function findAdjacentMakeupRequests($makeups, $pivotTimeslotId)
    {
        if ($makeups->isEmpty()) {
            return collect([]);
        }

        // Map các đề xuất theo timeslot_id
        $makeupByTimeslotId = $makeups->keyBy('timeslot_id');
        
        if (!$makeupByTimeslotId->has($pivotTimeslotId)) {
            return collect([]);
        }

        $pivotMakeup = $makeupByTimeslotId->get($pivotTimeslotId);
        if (!$pivotMakeup->leave || !$pivotMakeup->leave->schedule) {
            return collect([$pivotMakeup]);
        }

        $origSchedule = $pivotMakeup->leave->schedule;
        $assignmentId = $origSchedule->assignment_id;
        $sessionDate = $origSchedule->session_date->format('Y-m-d');

        // Lấy TẤT CẢ schedules gốc của assignment trong ngày
        $allSchedulesOfDay = \App\Models\Schedule::query()
            ->with('timeslot')
            ->where('assignment_id', $assignmentId)
            ->whereDate('session_date', $sessionDate)
            ->get();

        if ($allSchedulesOfDay->isEmpty()) {
            return collect([$pivotMakeup]);
        }

        // Parse pivot timeslot code
        $pivotTimeslot = \App\Models\Timeslot::find($pivotTimeslotId);
        if (!$pivotTimeslot || !preg_match('/^(.+?)(\d+)$/', $pivotTimeslot->code, $matches)) {
            return collect([$pivotMakeup]);
        }

        $prefix = $matches[1];
        $pivotNumber = (int)$matches[2];

        // Map schedule theo số thứ tự timeslot
        $scheduleByNumber = [];
        foreach ($allSchedulesOfDay as $sched) {
            if ($sched->timeslot && preg_match('/^(.+?)(\d+)$/', $sched->timeslot->code, $m) && $m[1] === $prefix) {
                $num = (int)$m[2];
                $scheduleByNumber[$num] = $sched;
            }
        }

        // Tìm dãy LIÊN TỤC
        $adjacentNumbers = [$pivotNumber];
        
        // Backward
        $currentNumber = $pivotNumber - 1;
        while ($currentNumber > 0) {
            if (!isset($scheduleByNumber[$currentNumber])) {
                break;
            }
            
            // Kiểm tra makeup request tồn tại cho tiết này
            $expectedTimeslotCode = $prefix . $currentNumber;
            $expectedTimeslot = \App\Models\Timeslot::where('code', $expectedTimeslotCode)->first();
            
            if (!$expectedTimeslot || !$makeupByTimeslotId->has($expectedTimeslot->id)) {
                break;
            }
            
            array_unshift($adjacentNumbers, $currentNumber);
            $currentNumber--;
        }

        // Forward
        $currentNumber = $pivotNumber + 1;
        while (true) {
            if (!isset($scheduleByNumber[$currentNumber])) {
                break;
            }
            
            // Kiểm tra makeup request tồn tại cho tiết này
            $expectedTimeslotCode = $prefix . $currentNumber;
            $expectedTimeslot = \App\Models\Timeslot::where('code', $expectedTimeslotCode)->first();
            
            if (!$expectedTimeslot || !$makeupByTimeslotId->has($expectedTimeslot->id)) {
                break;
            }
            
            $adjacentNumbers[] = $currentNumber;
            $currentNumber++;
        }

        // Lấy danh sách timeslot IDs
        $adjacentTimeslotIds = [];
        foreach ($adjacentNumbers as $num) {
            $code = $prefix . $num;
            $ts = \App\Models\Timeslot::where('code', $code)->first();
            if ($ts) {
                $adjacentTimeslotIds[] = $ts->id;
            }
        }

        \Log::debug('Adjacent makeup grouping', [
            'pivot_code' => $pivotTimeslot->code,
            'pivot_number' => $pivotNumber,
            'adjacent_numbers' => $adjacentNumbers,
            'adjacent_timeslot_ids' => $adjacentTimeslotIds,
        ]);

        return $makeups->filter(fn($makeup) => in_array($makeup->timeslot_id, $adjacentTimeslotIds));
    }
}
