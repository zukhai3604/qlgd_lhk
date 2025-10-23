<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\LeaveRequestStoreRequest;
use App\Http\Requests\Lecturer\LeaveRequestUpdateRequest;
use App\Http\Resources\Lecturer\LeaveRequestResource;
use App\Models\LeaveRequest;
use App\Models\Schedule;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class LeaveRequestController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/leave-requests",
     *   operationId="lecturerLeaveIndex",
     *   tags={"Lecturer - Nghỉ dạy"},
     *   summary="Danh sách đơn xin nghỉ của giảng viên",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="status",
     *     in="query",
     *     description="Lọc theo trạng thái (PENDING, APPROVED, REJECTED, CANCELED)",
     *     @OA\Schema(type="string")
     *   ),
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
    public function index(Request $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;

        $query = LeaveRequest::query()
            ->where('lecturer_id', $lecturerId)
            ->orderByDesc('id');

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $items = $query->paginate(20);

        return LeaveRequestResource::collection($items)
            ->additional(['meta' => ['total' => $items->total()]]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/leave-requests",
     *   operationId="lecturerLeaveStore",
     *   tags={"Lecturer - Nghỉ dạy"},
     *   summary="Tạo đơn xin nghỉ dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"schedule_id","reason"},
     *       @OA\Property(property="schedule_id", type="integer", example=345),
     *       @OA\Property(property="reason", type="string", example="Ốm đột xuất")
     *     )
     *   ),
     *   @OA\Response(
     *     response=201,
     *     description="Tạo đơn nghỉ thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/LeaveRequestResource")
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy lịch dạy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Dữ liệu không hợp lệ",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function store(LeaveRequestStoreRequest $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        $data = $request->validated();

        $schedule = Schedule::with('assignment')->find($data['schedule_id']);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy lịch dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== $lecturerId) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $leave = new LeaveRequest();
        $leave->schedule_id = $schedule->id;
        $leave->lecturer_id = $lecturerId;
        $leave->reason = $data['reason'];
        $leave->status = 'PENDING';
        $leave->save();

        return response()->json(['data' => new LeaveRequestResource($leave)], 201);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/leave-requests/{id}",
     *   operationId="lecturerLeaveShow",
     *   tags={"Lecturer - Nghỉ dạy"},
     *   summary="Chi tiết đơn nghỉ",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=100)),
     *   @OA\Response(
     *     response=200,
     *     description="Thông tin đơn nghỉ",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/LeaveRequestResource")
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function show(Request $request, int $id)
    {
        $leave = LeaveRequest::find($id);
        if (!$leave) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }

        if ($leave->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        return response()->json(['data' => new LeaveRequestResource($leave)]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/leave-requests/{id}",
     *   operationId="lecturerLeaveUpdate",
     *   tags={"Lecturer - Nghỉ dạy"},
     *   summary="Chỉnh sửa đơn nghỉ (khi còn PENDING)",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=100)),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="reason", type="string", example="Có công tác gấp"),
     *       @OA\Property(property="note", type="string", nullable=true, example="Đính kèm giấy xác nhận")
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Cập nhật thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/LeaveRequestResource")
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Không thể chỉnh sửa đơn đã xử lý",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function update(LeaveRequestUpdateRequest $request, int $id)
    {
        $leave = LeaveRequest::find($id);
        if (!$leave) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }

        if ($leave->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        if ($leave->status !== 'PENDING') {
            return response()->json(['message' => 'Chỉ được chỉnh sửa khi đơn còn trạng thái PENDING'], 422);
        }

        $leave->fill($request->validated());
        $leave->save();

        return response()->json(['data' => new LeaveRequestResource($leave)]);
    }

    /**
     * @OA\Delete(
     *   path="/api/lecturer/leave-requests/{id}",
     *   operationId="lecturerLeaveDestroy",
     *   tags={"Lecturer - Nghỉ dạy"},
     *   summary="Hủy đơn nghỉ",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=100)),
     *   @OA\Response(response=204, description="Đã hủy"),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Chỉ hủy được đơn ở trạng thái PENDING",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function destroy(Request $request, int $id)
    {
        $leave = LeaveRequest::find($id);
        if (!$leave) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }

        if ($leave->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        if ($leave->status !== 'PENDING') {
            return response()->json(['message' => 'Chỉ hủy đơn khi còn trạng thái PENDING'], 422);
        }

        $leave->delete();

        return response()->noContent();
    }
}
