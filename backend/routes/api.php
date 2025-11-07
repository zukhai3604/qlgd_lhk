<?php

use Illuminate\Support\Facades\Route;

// ===== Controllers chung =====
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\Api\HealthController; // Lưu ý: namespace 'Api' (chữ i thường)

// Danh mục dùng chung
use App\Http\Controllers\Api\FacultyController as ApiFacultyController;
use App\Http\Controllers\Api\DepartmentController as ApiDepartmentController;

// ====== ADMIN ======
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UserController as AdminUserController;
use App\Http\Controllers\Admin\ProfileController as AdminProfileController;
use App\Http\Controllers\Admin\AuditLogController;
use App\Http\Controllers\Admin\SystemReportController;
use App\Http\Controllers\Admin\AdminNotificationController;


// ====== PHÒNG ĐÀO TẠO ======
use App\Http\Controllers\TrainingDepartment\ProfileController as TDProfileController;
use App\Http\Controllers\TrainingDepartment\ApprovalController;

// ====== LECTURER (web guard) ======
use App\Http\Controllers\Lecturer\ScheduleController;
use App\Http\Controllers\Lecturer\LeaveController;
use App\Http\Controllers\Lecturer\ProfileController;
use App\Http\Controllers\Lecturer\ReportController;
use App\Http\Controllers\Lecturer\MaterialController;

// ====== LECTURER (API chuẩn hoá Bearer) ======
use App\Http\Controllers\API\Lecturer\LecturerProfileController as ApiLecturerProfileController;
use App\Http\Controllers\API\Lecturer\LecturerReportController as ApiLecturerReportController;
use App\Http\Controllers\API\Lecturer\ScheduleController as ApiLecturerScheduleController;
use App\Http\Controllers\API\Lecturer\TeachingSessionController as ApiTeachingSessionController;
use App\Http\Controllers\API\Lecturer\TeachingSessionWorkflowController as ApiTeachingSessionWorkflowController;
use App\Http\Controllers\API\Lecturer\AttendanceController as ApiAttendanceController;
use App\Http\Controllers\API\Lecturer\LeaveRequestController as ApiLeaveRequestController;
use App\Http\Controllers\API\Lecturer\MakeupRequestController as ApiMakeupRequestController;
use App\Http\Controllers\API\Lecturer\NotificationController as ApiNotificationController;
use App\Http\Controllers\API\Lecturer\StatsController as ApiStatsController;

/*
|--------------------------------------------------------------------------
| Public (no auth)
|--------------------------------------------------------------------------
*/
Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::get('/health', [HealthController::class, 'health']);
Route::get('/ping',   [HealthController::class, 'ping']);

/*
|--------------------------------------------------------------------------
| Authenticated (Sanctum) + ensure.active
|--------------------------------------------------------------------------
*/
Route::middleware(['auth:sanctum', 'ensure.active'])->group(function () {

    // ==== Auth session ====
    Route::get('/me',      [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/logout-all', [AuthController::class, 'logoutAll']); // FE đang dùng

    // ==== Danh mục chung ====
    Route::get('/faculties',   [ApiFacultyController::class, 'index']);
    Route::get('/departments', [ApiDepartmentController::class, 'index']);

    /*
    |----------------------------------------------------------------------
    | ADMIN AREA
    |----------------------------------------------------------------------
    */
    Route::prefix('admin')->middleware('role:ADMIN')->group(function () {

        // Hồ sơ admin
        Route::get('me/profile',   [AdminProfileController::class, 'show']);
        Route::patch('me/profile', [AdminProfileController::class, 'update']);

        // Dashboard stats (FE gọi /admin/dashboard/stats)
        Route::get('dashboard/stats', [DashboardController::class, 'stats']);

        // Users CRUD + các hành động tuỳ biến
        Route::apiResource('users', AdminUserController::class)
            ->only(['index','show','store','update','destroy']);

        // Các action đang dùng ở FE:
        Route::post('users/{user}/lock',           [AdminUserController::class, 'lock'])->whereNumber('user');
        Route::post('users/{user}/unlock',         [AdminUserController::class, 'unlock'])->whereNumber('user');
        Route::post('users/{user}/reset-password', [AdminUserController::class, 'resetPassword'])->whereNumber('user');

        // (Tuỳ chọn) phân quyền/role nếu có API:
        // Route::post('users/{user}/roles', [AdminUserController::class, 'updateRoles'])->whereNumber('user');

        // Audit logs (đã tạo ở phần trước)
        Route::get('logs',                    [AuditLogController::class, 'index']);
        Route::get('users/{id}/activity',     [AuditLogController::class, 'userActivity'])->whereNumber('id');
        
        // System Reports
        Route::get('reports', [SystemReportController::class, 'index']);
        Route::get('reports/statistics', [SystemReportController::class, 'statistics']);
        Route::get('reports/{id}', [SystemReportController::class, 'show'])->whereNumber('id');
        Route::patch('reports/{id}/status', [SystemReportController::class, 'updateStatus'])->whereNumber('id');
        Route::post('reports/{id}/comments', [SystemReportController::class, 'addComment'])->whereNumber('id');

        Route::get('notifications', [AdminNotificationController::class, 'index']);
        Route::get('notifications/unread_count', [AdminNotificationController::class, 'unreadCount']);
        Route::patch('notifications/{id}/read', [AdminNotificationController::class, 'markRead'])->whereNumber('id');
        Route::patch('notifications/read_all', [AdminNotificationController::class, 'markAllRead']);
    });

    /*
    |----------------------------------------------------------------------
    | TRAINING DEPARTMENT AREA
    |----------------------------------------------------------------------
    */
    Route::prefix('training_department')->middleware('role:DAO_TAO')->group(function () {
        Route::get('me/profile',   [TDProfileController::class, 'show']);
        Route::patch('me/profile', [TDProfileController::class, 'update']);

        // Phê duyệt đơn nghỉ
        Route::post('approvals/leave/{leave}', [ApprovalController::class, 'approveLeave'])->whereNumber('leave');
    });

    /*
    |----------------------------------------------------------------------
    | LECTURER AREA (legacy web controllers)
    |----------------------------------------------------------------------
    */
    Route::prefix('lecturer')->middleware('role:GIANG_VIEN')->group(function () {
        Route::get('profile', [ProfileController::class, 'show']);

        Route::get('schedule/week', [ScheduleController::class, 'getWeekSchedule']);
        Route::get('schedule/{id}', [ScheduleController::class, 'show'])->whereNumber('id');

        Route::post('schedule/{id}/report', [ReportController::class, 'store'])->whereNumber('id');

        // Tài liệu buổi học
        Route::get('schedule/{id}/materials',  [MaterialController::class, 'index'])->whereNumber('id');
        Route::post('schedule/{id}/materials', [MaterialController::class, 'store'])->whereNumber('id');

        // Đơn nghỉ
        Route::post('leaves',   [LeaveController::class, 'store']);
        Route::get('leaves/my', [LeaveController::class, 'my']);
    });
});

/*
|--------------------------------------------------------------------------
| LECTURER API (Bearer chuẩn hoá) - tách riêng cho app mobile/web FE
|--------------------------------------------------------------------------
*/
Route::prefix('lecturer')
    ->middleware(['auth:sanctum','ensure.active','role:GIANG_VIEN'])
    ->group(function () {

    // Profile + đổi mật khẩu
    Route::get('me/profile',         [ApiLecturerProfileController::class, 'show']);
    Route::patch('me/profile',       [ApiLecturerProfileController::class, 'update']);
    Route::post('me/change-password',[ApiLecturerProfileController::class, 'changePassword']);

    // Lịch
    Route::get('schedule', [ApiLecturerScheduleController::class, 'index']);

    // Buổi dạy
    Route::get('sessions',         [ApiTeachingSessionController::class, 'index']);
    Route::get('sessions/{id}',    [ApiTeachingSessionController::class, 'show'])->whereNumber('id');
    Route::patch('sessions/{id}',  [ApiTeachingSessionController::class, 'update'])->whereNumber('id');
    Route::post('sessions/{id}/start',  [ApiTeachingSessionWorkflowController::class, 'start'])->whereNumber('id');
    Route::post('sessions/{id}/finish', [ApiTeachingSessionWorkflowController::class, 'finish'])->whereNumber('id');

    // Điểm danh
    Route::get('sessions/{id}/attendance',  [ApiAttendanceController::class, 'show'])->whereNumber('id');
    Route::post('sessions/{id}/attendance', [ApiAttendanceController::class, 'store'])->whereNumber('id');

    // Đơn nghỉ + dạy bù
    Route::get('leave-requests',             [ApiLeaveRequestController::class, 'index']);
    Route::post('leave-requests',            [ApiLeaveRequestController::class, 'store']);
    Route::get('leave-requests/{id}',        [ApiLeaveRequestController::class, 'show'])->whereNumber('id');
    Route::patch('leave-requests/{id}',      [ApiLeaveRequestController::class, 'update'])->whereNumber('id');
    Route::delete('leave-requests/{id}',     [ApiLeaveRequestController::class, 'destroy'])->whereNumber('id');

    Route::get('makeup-requests',            [ApiMakeupRequestController::class, 'index']);
    Route::post('makeup-requests',           [ApiMakeupRequestController::class, 'store']);
    Route::get('makeup-requests/{id}',       [ApiMakeupRequestController::class, 'show'])->whereNumber('id');
    Route::patch('makeup-requests/{id}',     [ApiMakeupRequestController::class, 'update'])->whereNumber('id');
    Route::delete('makeup-requests/{id}',    [ApiMakeupRequestController::class, 'destroy'])->whereNumber('id');

    // Thông báo
    Route::get('notifications',          [ApiNotificationController::class, 'index']);
    Route::get('notifications/{id}',     [ApiNotificationController::class, 'show'])->whereNumber('id');
    Route::post('notifications/{id}/read', [ApiNotificationController::class, 'markRead'])->whereNumber('id');
    Route::delete('notifications/{id}',  [ApiNotificationController::class, 'destroy'])->whereNumber('id');

    // Thống kê
    Route::get('stats/teaching-hours', [ApiStatsController::class, 'teachingHours']);
});

/*
|--------------------------------------------------------------------------
| Reports (đang dùng trong FE)
|--------------------------------------------------------------------------
*/
Route::prefix('reports')
    ->middleware(['auth:sanctum','ensure.active'])
    ->group(function () {
        Route::get('lecturers/{lecturer}', [ApiLecturerReportController::class, 'show'])
            ->whereNumber('lecturer');
    });
