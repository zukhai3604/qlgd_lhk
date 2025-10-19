<?php

use Illuminate\Support\Facades\Route;

// Controllers
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\LeaveController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Lecturer\ScheduleController;
use App\Http\Controllers\TrainingDepartment\RequestController as TrRequestController;
use App\Http\Controllers\TrainingDepartment\ScheduleController as TrScheduleController;
use App\Http\Controllers\TrainingDepartment\ReportController as TrReportController;
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
        // 1) Đơn & Duyệt
        Route::get('requests', [TrRequestController::class, 'index']);
        Route::get('requests/{type}/{id}', [TrRequestController::class, 'show']); // type: leave|makeup
        Route::post('leave/{id}/approve',  [TrRequestController::class, 'approveLeave']);
        Route::post('leave/{id}/reject',   [TrRequestController::class, 'rejectLeave']);
        Route::post('makeup/{id}/approve', [TrRequestController::class, 'approveMakeup']);
        Route::post('makeup/{id}/reject',  [TrRequestController::class, 'rejectMakeup']);

        // 2) Lịch
        Route::get('schedules/week',        [TrScheduleController::class, 'week']);
        Route::get('schedules/month',       [TrScheduleController::class, 'month']);
        Route::get('schedules/conflicts',   [TrScheduleController::class, 'conflicts']);
        Route::post('schedules/generate',   [TrScheduleController::class, 'generate']);
        Route::post('schedules/bulk-adjust',[TrScheduleController::class, 'bulkAdjust']);

        // 3) Báo cáo + DataOps
        Route::get('reports/overview',           [TrReportController::class, 'semesterOverview']);
        Route::get('reports/subject-progress',   [TrReportController::class, 'subjectProgress']);
        Route::get('reports/lecturer-progress',  [TrReportController::class, 'lecturerProgress']);
        Route::get('reports/class-progress',     [TrReportController::class, 'classProgress']);
        Route::get('reports/subject-sessions',   [TrReportController::class, 'subjectSessions']);
        Route::post('data/push-class-students',  [TrReportController::class, 'pushClassStudents']);
    });

    // ----- GIẢNG VIÊN -----
    Route::middleware('role:GIANG_VIEN')->prefix('lecturer')->group(function () {
        Route::get('schedule/week', [ScheduleController::class, 'getWeekSchedule']);
        Route::post('leaves', [LeaveController::class, 'store']);   // POST /api/lecturer/leaves
        Route::get('leaves/my', [LeaveController::class, 'my']);    // GET  /api/lecturer/leaves/my
    });
});
