<?php
// app/Http/Controllers/Admin/UserActivityController.php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;

class UserActivityController extends Controller
{
    public function index(int $userId)
    {
        $logs = AuditLog::query()
            ->where('actor_id', $userId)            // nếu bạn muốn theo người thực hiện
            // ->orWhere(fn($q) => $q->where('entity_type','User')->where('entity_id',$userId)) // nếu muốn cả target
            ->latest('created_at')
            ->limit(50)
            ->get()
            ->map(function ($r) {
                // map về các key mà app đã hỗ trợ: title/message/action + created_at
                return [
                    'id'         => $r->id,
                    'title'      => ucfirst($r->action).' '.$r->entity_type,   // ví dụ: "Updated Schedule"
                    'created_at' => optional($r->created_at)->toIso8601String(),
                ];
            });

        return response()->json(['data' => $logs]);
    }
}
