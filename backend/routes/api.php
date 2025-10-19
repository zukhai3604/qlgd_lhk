<?php

use Illuminate\Support\Facades\Route;

// Controllers
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Lecturer\ScheduleController;
use App\Http\Controllers\Lecturer\LeaveController;                 // ✅ đúng namespace
use App\Http\Controllers\Lecturer\ProfileController;               // ✅ thêm import
use App\Http\Controllers\TrainingDepartment\ApprovalController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ===== Public =====
Route::post('/login', [AuthController::class, 'login'])->name('login');

// ===== Health (public) =====
Route::get('/health', fn() => response()->json(['ok' => true]));
Route::get('/ping',   fn() => response()->json(['pong' => now()]));

// ===== Authenticated =====
Route::middleware(['auth:sanctum', 'ensure.active'])->group(function () {

    // Me / Logout
    Route::get('/me',     [AuthController::class, 'me']);
    Route::post('/logout',[AuthController::class, 'logout']);

    // ----- ADMIN -----
    Route::middleware('role:ADMIN')->prefix('admin')->group(function () {
        Route::apiResource('users', UserController::class);
        // Ví dụ: Route::post('users/{user}/lock', [UserController::class,'lock']);
    });

    // ----- PHÒNG ĐÀO TẠO -----
    Route::middleware('role:DAO_TAO')->prefix('training_department')->group(function () {
        Route::post('approvals/leave/{leave}', [ApprovalController::class, 'approveLeave']);
    });

    // ----- GIẢNG VIÊN -----
    Route::middleware('role:GIANG_VIEN')->prefix('lecturer')->group(function () {
        // ✅ Hồ sơ giảng viên: trả về user + lecturer + department + faculty
        Route::get('profile', [ProfileController::class, 'show']);

        // Thời khóa biểu tuần
        Route::get('schedule/week', [ScheduleController::class, 'getWeekSchedule']);

        // Nghỉ dạy
        Route::post('leaves',   [LeaveController::class, 'store']);
        Route::get('leaves/my', [LeaveController::class, 'my']);

        // Báo cáo & tài liệu buổi học (nếu đã có controllers)
        Route::post('schedule/{id}/report',    [\App\Http\Controllers\Lecturer\ReportController::class, 'store']);
        Route::post('schedule/{id}/materials', [\App\Http\Controllers\Lecturer\MaterialController::class, 'upload']);
        Route::get('schedule/{id}/materials',  [\App\Http\Controllers\Lecturer\MaterialController::class, 'list']);
    });
});
