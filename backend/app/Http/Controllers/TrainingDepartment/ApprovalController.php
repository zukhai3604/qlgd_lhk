<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

/** @OA\Tag(name="Training Department - Approvals", description="Phê duyệt (DAO_TAO)") */
class ApprovalController extends Controller
{
    /** @OA\Post(
     *  path="/api/training_department/approvals/leave/{leave}",
     *  tags={"Training Department - Approvals"}, summary="Phê duyệt đơn nghỉ",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="leave", in="path", required=true, @OA\Schema(type="integer")),
     *  @OA\RequestBody(required=true, @OA\JsonContent(
     *    required={"status"},
     *    @OA\Property(property="status", type="string", example="APPROVED", description="APPROVED|REJECTED"),
     *    @OA\Property(property="note", type="string", nullable=true)
     *  )),
     *  @OA\Response(response=200, description="OK"),
     *  @OA\Response(response=403, description="Forbidden", @OA\JsonContent(ref="#/components/schemas/Error")),
     *  @OA\Response(response=404, description="Not Found", @OA\JsonContent(ref="#/components/schemas/Error"))
     * ) */
    public function approveLeave(Request $request, LeaveRequest $leave)
    {
        // Logic phê duyệt đơn nghỉ
    }
}
