<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\SessionUpdateRequest;
use App\Http\Resources\Lecturer\TeachingSessionResource;
use App\Models\Schedule;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class TeachingSessionController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/sessions",
     *   operationId="lecturerSessionsIndex",
     *   tags={"Lecturer - Buổi dạy"},
     *   summary="Danh sách buổi dạy của giảng viên",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="date",
     *     in="query",
     *     description="Lọc theo ngày cụ thể (YYYY-MM-DD)",
     *     @OA\Schema(type="string", format="date")
     *   ),
     *   @OA\Parameter(
     *     name="from",
     *     in="query",
     *     description="Ngày bắt đầu (YYYY-MM-DD)",
     *     @OA\Schema(type="string", format="date")
     *   ),
     *   @OA\Parameter(
     *     name="to",
     *     in="query",
     *     description="Ngày kết thúc (YYYY-MM-DD)",
     *     @OA\Schema(type="string", format="date")
     *   ),
     *   @OA\Parameter(
     *     name="status",
     *     in="query",
     *     description="Trạng thái buổi dạy (PLANNED, TEACHING, DONE...)",
     *     @OA\Schema(type="string")
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phân trang",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(ref="#/components/schemas/TeachingSessionResource")
     *       ),
     *       @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền truy cập",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function index(Request $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        if (!$lecturerId) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $query = Schedule::query()
            ->with(['assignment.subject', 'assignment.classUnit', 'room', 'timeslot'])
            ->whereHas('assignment', fn ($builder) => $builder->where('lecturer_id', $lecturerId));

        if ($date = $request->query('date')) {
            $query->whereDate('session_date', $date);
        }
        if ($from = $request->query('from')) {
            $query->whereDate('session_date', '>=', $from);
        }
        if ($to = $request->query('to')) {
            $query->whereDate('session_date', '<=', $to);
        }
        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        // Tăng per_page để giảm số requests (tối đa 100)
        $perPage = min((int)($request->query('per_page') ?: 20), 100);
        $items = $query->orderBy('session_date')->paginate($perPage);

        return TeachingSessionResource::collection($items)
            ->additional(['meta' => ['total' => $items->total()]]);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/sessions/{id}",
     *   operationId="lecturerSessionsShow",
     *   tags={"Lecturer - Buổi dạy"},
     *   summary="Chi tiết một buổi dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="id",
     *     in="path",
     *     required=true,
     *     @OA\Schema(type="integer", example=345)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Thông tin buổi dạy",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/TeachingSessionResource")
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền truy cập",
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
        $schedule = Schedule::with(['assignment.subject', 'assignment.classUnit', 'room', 'timeslot'])->find($id);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        return response()->json([
            'data' => new TeachingSessionResource($schedule),
        ]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/sessions/{id}",
     *   operationId="lecturerSessionsUpdate",
     *   tags={"Lecturer - Buổi dạy"},
     *   summary="Cập nhật thông tin buổi dạy (khi còn trạng thái PLANNED)",
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
     *       @OA\Property(property="note", type="string", example="Chuẩn bị bài thực hành"),
     *       @OA\Property(property="room_id", type="integer", nullable=true, example=12)
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Cập nhật thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/TeachingSessionResource")
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không có quyền truy cập",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Trạng thái không cho phép cập nhật",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function update(SessionUpdateRequest $request, int $id)
    {
        $schedule = Schedule::find($id);
        if (!$schedule) {
            return response()->json(['message' => 'Không tìm thấy buổi dạy'], 404);
        }

        if ($schedule->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        if ($schedule->status !== 'PLANNED') {
            return response()->json(['message' => 'Chỉ được chỉnh sửa khi buổi dạy còn trạng thái PLANNED'], 422);
        }

        $schedule->fill($request->validated());
        $schedule->save();
        $schedule->load(['assignment.subject', 'assignment.classUnit', 'room', 'timeslot']);

        return response()->json([
            'data' => new TeachingSessionResource($schedule),
        ]);
    }
}
