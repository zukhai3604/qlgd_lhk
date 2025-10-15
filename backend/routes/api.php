<?php

use Illuminate\Support\Facades\Route;

// Controllers
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\LeaveController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Lecturer\ScheduleController;
use App\Http\Controllers\TrainingDepartment\ApprovalController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ===== Public =====
Route::post('/login', [AuthController::class, 'login'])->name('login');

// ===== Authenticated =====
Route::get('/health', fn() => response()->json(['ok' => true]));

Route::get('/ping', fn() => response()->json(['pong' => now()]));

Route::middleware(['auth:sanctum', 'ensure.active'])->group(function () {

    // Me / Logout
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // ----- ADMIN -----
    Route::middleware('role:ADMIN')->prefix('admin')->group(function () {
        Route::apiResource('users', UserController::class);
        // Ví dụ thêm:
        // Route::post('users/{user}/lock', [UserController::class,'lock']);
    });

    // ----- PHÒNG ĐÀO TẠO -----
    Route::middleware('role:DAO_TAO')->prefix('training_department')->group(function () {
        Route::post('approvals/leave/{leave}', [ApprovalController::class, 'approveLeave']);
    });

    // ----- GIẢNG VIÊN -----
    Route::middleware('role:GIANG_VIEN')->prefix('lecturer')->group(function () {
        Route::get('schedule/week', [ScheduleController::class, 'getWeekSchedule']);
        Route::post('leaves', [LeaveController::class, 'store']);   // POST /api/lecturer/leaves
        Route::get('leaves/my', [LeaveController::class, 'my']);    // GET  /api/lecturer/leaves/my
    });
});
