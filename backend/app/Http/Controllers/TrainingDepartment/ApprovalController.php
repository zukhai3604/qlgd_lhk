<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

/**
 * @OA\Tag(
 *   name="Training Department - Approvals",
 *   description="Phê duyệt đơn của phòng Đào tạo (vai trò DAO_TAO)"
 * )
 */
class ApprovalController extends Controller
{
    /**
     * @OA\Post(
     *   path="/api/training_department/approvals/leave/{leave}",
     *   operationId="trainingApproveLeave",
     *   tags={"Training Department - Approvals"},
     *   summary="Phê duyệt / từ chối đơn nghỉ dạy",
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
     *     description="Cập nhật trạng thái đơn nghỉ",
     *     @OA\JsonContent(ref="#/components/schemas/LeaveRequestResource")
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function approveLeave(Request $request, LeaveRequest $leave)
    {
        // TODO: Hiện tại controller chưa có logic thực thi.
    }
}
