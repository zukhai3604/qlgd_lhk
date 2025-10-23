<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\MakeupRequestStoreRequest;
use App\Http\Requests\Lecturer\MakeupRequestUpdateRequest;
use App\Http\Resources\Lecturer\MakeupRequestResource;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class MakeupRequestController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/makeup-requests",
     *   operationId="lecturerMakeupIndex",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Danh sách đề xuất dạy bù",
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
    public function index(Request $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;

        $items = MakeupRequest::query()
            ->whereHas('leave', fn ($builder) => $builder->where('lecturer_id', $lecturerId))
            ->orderByDesc('id')
            ->paginate(20);

        return MakeupRequestResource::collection($items)
            ->additional(['meta' => ['total' => $items->total()]]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/makeup-requests",
     *   operationId="lecturerMakeupStore",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Đề xuất buổi dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"leave_request_id","suggested_date","timeslot_id"},
     *       @OA\Property(property="leave_request_id", type="integer", example=100),
     *       @OA\Property(property="suggested_date", type="string", format="date", example="2025-10-28"),
     *       @OA\Property(property="timeslot_id", type="integer", example=4),
     *       @OA\Property(property="room_id", type="integer", nullable=true, example=12),
     *       @OA\Property(property="note", type="string", nullable=true, example="Ưu tiên phòng lab")
     *     )
     *   ),
     *   @OA\Response(
     *     response=201,
     *     description="Tạo đề xuất dạy bù thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy đơn nghỉ", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=422, description="Dữ liệu không hợp lệ", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function store(MakeupRequestStoreRequest $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        $data = $request->validated();

        $leave = LeaveRequest::find($data['leave_request_id']);
        if (!$leave) {
            return response()->json(['message' => 'Không tìm thấy yêu cầu nghỉ'], 404);
        }
        if ($leave->lecturer_id !== $lecturerId) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $makeup = new MakeupRequest($data);
        $makeup->status = 'PENDING';
        $makeup->save();

        return response()->json(['data' => new MakeupRequestResource($makeup)], 201);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/makeup-requests/{id}",
     *   operationId="lecturerMakeupShow",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Chi tiết đề xuất dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=200)),
     *   @OA\Response(
     *     response=200,
     *     description="Chi tiết đề xuất",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function show(Request $request, int $id)
    {
        $makeup = MakeupRequest::with('leave')->find($id);
        if (!$makeup) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($makeup->leave?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        return response()->json(['data' => new MakeupRequestResource($makeup)]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/makeup-requests/{id}",
     *   operationId="lecturerMakeupUpdate",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Chỉnh sửa đề xuất dạy bù (khi còn PENDING)",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=200)),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="suggested_date", type="string", format="date", example="2025-10-30"),
     *       @OA\Property(property="timeslot_id", type="integer", example=5),
     *       @OA\Property(property="room_id", type="integer", nullable=true, example=9),
     *       @OA\Property(property="note", type="string", nullable=true, example="Đề xuất phòng đa năng")
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Cập nhật thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=422, description="Chỉ chỉnh sửa khi PENDING", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function update(MakeupRequestUpdateRequest $request, int $id)
    {
        $makeup = MakeupRequest::with('leave')->find($id);
        if (!$makeup) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($makeup->leave?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }
        if ($makeup->status !== 'PENDING') {
            return response()->json(['message' => 'Chỉ chỉnh sửa khi đề xuất còn PENDING'], 422);
        }

        $makeup->fill($request->validated());
        $makeup->save();

        return response()->json(['data' => new MakeupRequestResource($makeup)]);
    }

    /**
     * @OA\Delete(
     *   path="/api/lecturer/makeup-requests/{id}",
     *   operationId="lecturerMakeupDestroy",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Hủy đề xuất dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=200)),
     *   @OA\Response(response=204, description="Đã hủy"),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=422, description="Chỉ hủy khi PENDING", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function destroy(Request $request, int $id)
    {
        $makeup = MakeupRequest::with('leave')->find($id);
        if (!$makeup) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($makeup->leave?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }
        if ($makeup->status !== 'PENDING') {
            return response()->json(['message' => 'Chỉ hủy được đề xuất còn PENDING'], 422);
        }

        $makeup->delete();

        return response()->noContent();
    }
}
