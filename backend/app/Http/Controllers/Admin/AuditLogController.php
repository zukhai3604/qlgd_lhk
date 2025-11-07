<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;

class AuditLogController extends Controller
{
    /**
     * Lấy toàn bộ log (admin xem tất cả)
     */
    public function index(Request $request)
    {
        $query = AuditLog::query()->with('actor:id,name,email');

        if ($request->filled('action')) {
            $query->where('action', 'like', "%{$request->action}%");
        }

        if ($request->filled('entity_type')) {
            $query->where('entity_type', $request->entity_type);
        }

        if ($request->filled('from') && $request->filled('to')) {
            $query->whereBetween('created_at', [$request->from, $request->to]);
        }

        $logs = $query->orderByDesc('created_at')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $logs,
        ]);
    }

    /**
     * Lấy log hoạt động của 1 người dùng cụ thể (actor)
     */
    public function userActivity($id)
    {
        $logs = AuditLog::where('actor_id', $id)
            ->orderByDesc('created_at')
            ->paginate(20, ['id', 'action', 'entity_type', 'entity_id', 'payload', 'created_at']);

        return response()->json([
            'success' => true,
            'data' => $logs,
        ]);
    }
}
