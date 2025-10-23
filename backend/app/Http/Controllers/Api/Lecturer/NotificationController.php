<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Resources\Lecturer\NotificationResource;
use App\Models\Notification;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class NotificationController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/notifications",
     *   operationId="lecturerNotificationsIndex",
     *   tags={"Lecturer - Thông báo"},
     *   summary="Danh sách thông báo của giảng viên",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="is_read",
     *     in="query",
     *     description="Lọc theo trạng thái đã đọc (true/false)",
     *     @OA\Schema(type="boolean")
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phân trang",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(ref="#/components/schemas/NotificationResource")
     *       ),
     *       @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
     *     )
     *   )
     * )
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $query = Notification::query()->where('to_user_id', $userId);

        if (!is_null($isRead = $request->query('is_read'))) {
            $query->where('status', filter_var($isRead, FILTER_VALIDATE_BOOLEAN) ? 'READ' : 'UNREAD');
        }

        $items = $query->orderByDesc('created_at')->paginate(20);

        return NotificationResource::collection($items)
            ->additional(['meta' => ['total' => $items->total()]]);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/notifications/{id}",
     *   operationId="lecturerNotificationsShow",
     *   tags={"Lecturer - Thông báo"},
     *   summary="Xem chi tiết thông báo",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=501)),
     *   @OA\Response(
     *     response=200,
     *     description="Thông báo",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/NotificationResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function show(Request $request, int $id)
    {
        $notification = Notification::find($id);
        if (!$notification) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($notification->to_user_id !== $request->user()->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        return response()->json(['data' => new NotificationResource($notification)]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/notifications/{id}/read",
     *   operationId="lecturerNotificationsMarkRead",
     *   tags={"Lecturer - Thông báo"},
     *   summary="Đánh dấu đã đọc thông báo",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=501)),
     *   @OA\Response(
     *     response=200,
     *     description="Đánh dấu đã đọc thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/NotificationResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function markRead(Request $request, int $id)
    {
        $notification = Notification::find($id);
        if (!$notification) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($notification->to_user_id !== $request->user()->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $notification->status = 'READ';
        $notification->read_at = now();
        $notification->save();

        return response()->json(['data' => new NotificationResource($notification)]);
    }

    /**
     * @OA\Delete(
     *   path="/api/lecturer/notifications/{id}",
     *   operationId="lecturerNotificationsDestroy",
     *   tags={"Lecturer - Thông báo"},
     *   summary="Xóa thông báo",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=501)),
     *   @OA\Response(response=204, description="Đã xóa"),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function destroy(Request $request, int $id)
    {
        $notification = Notification::find($id);
        if (!$notification) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($notification->to_user_id !== $request->user()->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $notification->delete();

        return response()->noContent();
    }
}
