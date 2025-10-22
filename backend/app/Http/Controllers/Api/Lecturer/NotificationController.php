<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Resources\Lecturer\NotificationResource;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $q = Notification::query()->where('to_user_id', $userId);
        if (!is_null($r = $request->query('is_read'))) {
            $q->where('status', filter_var($r, FILTER_VALIDATE_BOOLEAN) ? 'READ' : 'UNREAD');
        }
        $items = $q->orderByDesc('created_at')->paginate(20);
        return NotificationResource::collection($items)->additional(['meta' => ['total' => $items->total()]]);
    }

    public function show(Request $request, $id)
    {
        $n = Notification::find($id);
        if (!$n) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($n->to_user_id !== $request->user()->id) return response()->json(['message' => 'Forbidden'], 403);
        return response()->json(['data' => new NotificationResource($n)]);
    }

    public function markRead(Request $request, $id)
    {
        $n = Notification::find($id);
        if (!$n) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($n->to_user_id !== $request->user()->id) return response()->json(['message' => 'Forbidden'], 403);
        $n->status = 'READ';
        $n->read_at = now();
        $n->save();
        return response()->json(['data' => new NotificationResource($n)]);
    }

    public function destroy(Request $request, $id)
    {
        $n = Notification::find($id);
        if (!$n) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($n->to_user_id !== $request->user()->id) return response()->json(['message' => 'Forbidden'], 403);
        $n->delete();
        return response()->noContent();
    }
}

