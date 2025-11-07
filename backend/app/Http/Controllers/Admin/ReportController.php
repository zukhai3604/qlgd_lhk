<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\LeaveRequest; // Giả sử
use Illuminate\Support\Facades\DB;

class ReportController extends Controller {
    public function system() {
        $usersByRole = User::select('role', DB::raw('count(*) as total'))
            ->groupBy('role')->get();

        $requestsByStatus = LeaveRequest::select('status', DB::raw('count(*) as total'))
            ->where('created_at', '>=', now()->subDays(30)) // Thống kê 30 ngày qua
            ->groupBy('status')->get();

        return response()->json([
            'users_by_role' => $usersByRole,
            'requests_by_status_30d' => $requestsByStatus,
        ]);
    }
}