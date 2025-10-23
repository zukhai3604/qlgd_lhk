<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\Schedule;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class TeachingSessionWorkflowController extends Controller
{
    /**
     * @OA\Post(
     *   path="/api/lecturer/sessions/{id}/start",
     *   operationId="lecturerSessionStart",
     *   tags={"Lecturer - Buổi dạy"},
     *   summary="Bắt đầu buổi dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="id",
     *     in="path",
     *     required=true,
     *     @OA\Schema(type="integer", example=345)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Bắt đầu buổi dạy thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", type="object",
     *         @OA\Property(property="id", type="integer", example=345),
     *         @OA\Property(property="status", type="string", example="TEACHING")
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
     *     description="Trạng thái không hợp lệ để bắt đầu",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function start(Request $request, int $id)
    {
        $schedule = Schedule::find($id);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        if ($schedule->status !== 'PLANNED') {
            return response()->json(['message' => 'Chỉ được bắt đầu khi buổi dạy còn trạng thái PLANNED'], 422);
        }

        $schedule->status = 'TEACHING';
        $schedule->save();

        return response()->json([
            'data' => [
                'id' => $schedule->id,
                'status' => $schedule->status,
            ],
        ]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/sessions/{id}/finish",
     *   operationId="lecturerSessionFinish",
     *   tags={"Lecturer - Buổi dạy"},
     *   summary="Kết thúc buổi dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="id",
     *     in="path",
     *     required=true,
     *     @OA\Schema(type="integer", example=345)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Hoàn tất buổi dạy",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", type="object",
     *         @OA\Property(property="id", type="integer", example=345),
     *         @OA\Property(property="status", type="string", example="DONE")
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
     *     description="Chưa điểm danh hoặc trạng thái không cho phép hoàn tất",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function finish(Request $request, int $id)
    {
        $schedule = Schedule::find($id);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        if (!in_array($schedule->status, ['PLANNED', 'TEACHING'], true)) {
            return response()->json(['message' => 'Chỉ kết thúc khi buổi dạy đang ở trạng thái PLANNED hoặc TEACHING'], 422);
        }

        $hasAttendance = AttendanceRecord::where('schedule_id', $schedule->id)->exists();
        if (!$hasAttendance) {
            return response()->json(['message' => 'Cần điểm danh trước khi hoàn tất buổi dạy'], 422);
        }

        $schedule->status = 'DONE';
        $schedule->save();

        return response()->json([
            'data' => [
                'id' => $schedule->id,
                'status' => $schedule->status,
            ],
        ]);
    }
}
