<?php
namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\ScheduleReportRequest;
use App\Models\Schedule;
use OpenApi\Annotations as OA;

/** @OA\Tag(name="Lecturer - Report", description="Báo cáo/bút ký buổi học") */
class ReportController extends Controller
{
    /** @OA\Post(
     *  path="/api/lecturer/schedule/{id}/report", tags={"Lecturer - Report"}, summary="Nộp báo cáo",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *  @OA\RequestBody(required=true, @OA\JsonContent(
     *    @OA\Property(property="status", type="string", nullable=true, example="DONE"),
     *    @OA\Property(property="note", type="string", nullable=true, description="Ghi chú ngắn hoặc báo cáo chi tiết"),
     *    @OA\Property(property="content", type="string", nullable=true, description="Nội dung đã dạy"),
     *    @OA\Property(property="issues", type="string", nullable=true, description="Vấn đề gặp phải"),
     *    @OA\Property(property="next_plan", type="string", nullable=true, description="Kế hoạch tiếp theo")
     *  )),
     *  @OA\Response(response=200, description="Success"),
     *  @OA\Response(response=403, description="Forbidden"),
     *  @OA\Response(response=404, description="Not Found"),
     *  @OA\Response(response=422, description="Validation Error")
     * ) */
    public function store(ScheduleReportRequest $request, Schedule $schedule)
    {
        \Log::info('ReportController: Method called', [
            'schedule_id' => $schedule->id,
            'user_id' => $request->user()?->id,
        ]);
        
        try {
            $user = $request->user();
            
            // Kiểm tra quyền: chỉ giảng viên sở hữu buổi học mới được báo cáo
            $lecturerId = optional($user->lecturer)->id;
            if (!$lecturerId || $schedule->assignment?->lecturer_id !== $lecturerId) {
                \Log::warning('ReportController: Permission denied', [
                    'schedule_id' => $schedule->id,
                    'lecturer_id' => $lecturerId,
                    'schedule_lecturer_id' => $schedule->assignment?->lecturer_id,
                ]);
                return response()->json(['message' => 'Không có quyền truy cập'], 403);
            }

            // Kiểm tra trạng thái: không cho phép thay đổi status nếu đã DONE hoặc CANCELED
            $currentStatus = strtoupper($schedule->status ?? 'PLANNED');
            $isFinalized = in_array($currentStatus, ['DONE', 'CANCELED']);
            
            if ($isFinalized && $request->has('status')) {
                return response()->json([
                    'message' => 'Không thể thay đổi trạng thái của buổi học đã hoàn thành hoặc đã hủy'
                ], 422);
            }

            // Gộp tất cả thông tin vào schedules.note
            $noteParts = [];
            
            if ($request->filled('note')) {
                $noteParts[] = $request->note;
            }
            
            if ($request->filled('content')) {
                $noteParts[] = "\n\n=== NỘI DUNG ĐÃ DẠY ===\n" . $request->content;
            }
            
            if ($request->filled('issues')) {
                $noteParts[] = "\n\n=== VẤN ĐỀ GẶP PHẢI ===\n" . $request->issues;
            }
            
            if ($request->filled('next_plan')) {
                $noteParts[] = "\n\n=== KẾ HOẠCH TIẾP THEO ===\n" . $request->next_plan;
            }
            
            $combinedNote = !empty($noteParts) ? implode('', $noteParts) : null;

            // Cập nhật schedule
            // Luôn cập nhật note nếu có trong request (kể cả khi null để có thể xóa)
            \Log::info('ReportController: Request received', [
                'schedule_id' => $schedule->id,
                'has_note' => $request->has('note'),
                'note_value' => $request->input('note'),
                'filled_note' => $request->filled('note'),
                'all_request_data' => $request->all(),
            ]);
            
            if ($request->has('note')) {
                $schedule->note = $combinedNote;
                \Log::info('ReportController: Updating note', [
                    'schedule_id' => $schedule->id,
                    'note_value' => $combinedNote,
                    'has_note_in_request' => $request->has('note'),
                    'request_note' => $request->input('note'),
                    'combined_note' => $combinedNote,
                ]);
            } else {
                \Log::warning('ReportController: Note not in request', [
                    'schedule_id' => $schedule->id,
                    'request_keys' => array_keys($request->all()),
                ]);
            }
            
            // Cập nhật status nếu được gửi và chưa final
            if ($request->has('status') && !$isFinalized) {
                $newStatus = strtoupper($request->status);
                // Validate status hợp lệ
                $validStatuses = ['PLANNED', 'TEACHING', 'DONE', 'CANCELED'];
                if (in_array($newStatus, $validStatuses)) {
                    $schedule->status = $newStatus;
                }
            }
            
            $saveResult = $schedule->save();
            \Log::info('ReportController: Save result', [
                'schedule_id' => $schedule->id,
                'save_result' => $saveResult,
                'note_before_refresh' => $schedule->note,
            ]);
            
            // Refresh model để đảm bảo lấy giá trị mới nhất từ DB
            $schedule->refresh();
            
            \Log::info('ReportController: After refresh', [
                'schedule_id' => $schedule->id,
                'note_after_refresh' => $schedule->note,
            ]);
            
            // Load lại relationships để trả về đầy đủ
            $schedule->load(['assignment.subject', 'assignment.classUnit', 'room', 'timeslot']);

            $responseData = [
                'message' => 'Đã lưu báo cáo buổi học',
                'data' => [
                    'id' => $schedule->id,
                    'status' => $schedule->status,
                    'note' => $schedule->note,
                ]
            ];
            
            \Log::info('ReportController: Success - Returning response', [
                'schedule_id' => $schedule->id,
                'saved_note' => $schedule->note,
                'saved_status' => $schedule->status,
                'response_data' => $responseData,
            ]);

            return response()->json($responseData, 200, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        } catch (\Exception $e) {
            \Log::error('ReportController: Exception', [
                'schedule_id' => $schedule->id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'Có lỗi xảy ra khi lưu báo cáo: ' . $e->getMessage()
            ], 500, [], JSON_UNESCAPED_UNICODE);
        }
    }
}
