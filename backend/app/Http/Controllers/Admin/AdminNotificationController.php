<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\Notification;

class AdminNotificationController extends Controller
{
    public function index(Request $req)
    {
        try {
            $user = $req->user();
            if (!$user) {
                return response()->json([
                    'data' => [],
                    'current_page' => 1,
                    'total' => 0
                ]);
            }

            $type = $req->get('type'); // 'report'...
            $q = Notification::query()
                ->where('to_user_id', $user->id)
                ->when($type, fn($qq) => $qq->where('type', $type))
                ->orderByDesc('created_at');

            $data = $q->paginate(20);
            return response()->json($data);
        } catch (\Exception $e) {
            Log::error('Notification index error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            // Return empty list instead of 500 error
            return response()->json([
                'data' => [],
                'current_page' => 1,
                'total' => 0,
                'error' => $e->getMessage()
            ]);
        }
    }

    public function unreadCount(Request $req)
    {
        $user = $req->user();
        $count = Notification::where('to_user_id', $user->id)
            ->where(function($q) {
                $q->where('status', 'UNREAD')
                  ->orWhereNull('read_at');
            })
            ->count();
        return response()->json(['unread' => $count]);
    }

    public function markRead(Request $req, $id)
    {
        $user = $req->user();
        $n = Notification::where('id', $id)->where('to_user_id', $user->id)->firstOrFail();
        $n->status = 'READ';
        $n->read_at = now();
        $n->save();
        return response()->json(['success' => true]);
    }

    public function markAllRead(Request $req)
    {
        $user = $req->user();
        Notification::where('to_user_id', $user->id)
            ->where(function($q) {
                $q->where('status', 'UNREAD')
                  ->orWhereNull('read_at');
            })
            ->update([
                'status' => 'READ',
                'read_at' => now()
            ]);
        return response()->json(['success' => true]);
    }
}
