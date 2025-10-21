<?php

use Illuminate\Support\Facades\Route;

// Controllers
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Lecturer\ScheduleController;
use App\Http\Controllers\Lecturer\LeaveController;
use App\Http\Controllers\Lecturer\ProfileController;
use App\Http\Controllers\TrainingDepartment\ApprovalController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ReportController;

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

    // ===== NHÓM API CÁ NHÂN (ME) =====
    Route::get('/me',        [AuthController::class, 'me']);
    Route::post('/logout',     [AuthController::class, 'logout']);
    Route::post('/logout-all', [AuthController::class, 'logoutAll']);
    
    // API TỰ ĐỔI MẬT KHẨU (cần old_password, new_password)
    Route::put('/me/reset-password', [ProfileController::class, 'updatePassword']);


    // ===== NHÓM API ADMIN =====
    Route::middleware('role:ADMIN')->prefix('admin')->group(function () {
        
        // API ADMIN ĐẶT LẠI MẬT KHẨU (chỉ cần new_password)
        Route::post('users/{user}/reset-password', [UserController::class, 'resetPassword']);
        
        // Các route khác của Admin
        Route::post('users/{user}/lock', [UserController::class,'lock']);
        Route::post('users/{user}/unlock', [UserController::class,'unlock']);
        Route::get('dashboard/stats', [DashboardController::class, 'getStats']);
        Route::get('reports/system', [ReportController::class, 'system']);

        // Route Resource (nên đặt cuối cùng trong nhóm)
        Route::apiResource('users', UserController::class);
    });

    // ----- PHÒNG ĐÀO TẠO -----
    Route::middleware('role:DAO_TAO')->prefix('training_department')->group(function () {
        Route::post('approvals/leave/{leave}', [ApprovalController::class, 'approveLeave']);
    });

    // ----- GIẢNG VIÊN -----
    Route::middleware('role:GIANG_VIEN')->prefix('lecturer')->group(function () {
        Route::get('profile', [ProfileController::class, 'show']);
        Route::get('schedule/week', [ScheduleController::class, 'getWeekSchedule']);
        Route::post('leaves',   [LeaveController::class, 'store']);
        Route::get('leaves/my', [LeaveController::class, 'my']);
        
        // (Bạn nên import ReportController và MaterialController ở trên đầu)
        Route::post('schedule/{id}/report',    [\App\Http\Controllers\Lecturer\ReportController::class, 'store']);
        Route::post('schedule/{id}/materials', [\App\Http\Controllers\Lecturer\MaterialController::class, 'upload']);
        Route::get('schedule/{id}/materials',  [\App\Http\Controllers\Lecturer\MaterialController::class, 'list']);
    });
});