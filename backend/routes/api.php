<?php

use Illuminate\Support\Facades\Route;

// Controllers
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\ProfileController as AdminProfileController;
use App\Http\Controllers\Lecturer\ScheduleController;
use App\Http\Controllers\Lecturer\LeaveController;
use App\Http\Controllers\Lecturer\ProfileController;
use App\Http\Controllers\Lecturer\ReportController;
use App\Http\Controllers\Lecturer\MaterialController;
use App\Http\Controllers\TrainingDepartment\ApprovalController;
use App\Http\Controllers\TrainingDepartment\ProfileController as TDProfileController;
use App\Http\Controllers\Api\HealthController; // <- THASM DANG NAY (Chu y: Api, khong phai API)
use App\Http\Controllers\Api\FacultyController as ApiFacultyController;
use App\Http\Controllers\Api\DepartmentController as ApiDepartmentController;
use App\Http\Controllers\Api\RoomController as ApiRoomController;
use App\Http\Controllers\Api\TimeslotController as ApiTimeslotController;

// --- API Lecturer module (Bearer token)
use App\Http\Controllers\API\Lecturer\LecturerProfileController as ApiLecturerProfileController;
use App\Http\Controllers\API\Lecturer\LecturerReportController as ApiLecturerReportController;
use App\Http\Controllers\API\Lecturer\ScheduleController as ApiLecturerScheduleController;
use App\Http\Controllers\API\Lecturer\TeachingSessionController as ApiTeachingSessionController;
use App\Http\Controllers\API\Lecturer\TeachingSessionWorkflowController as ApiTeachingSessionWorkflowController;
use App\Http\Controllers\Api\Lecturer\AttendanceController as ApiAttendanceController;
use App\Http\Controllers\API\Lecturer\LeaveRequestController as ApiLeaveRequestController;
use App\Http\Controllers\API\Lecturer\MakeupRequestController as ApiMakeupRequestController;
use App\Http\Controllers\API\Lecturer\NotificationController as ApiNotificationController;
use App\Http\Controllers\API\Lecturer\StatsController as ApiStatsController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::post('/login', [AuthController::class, 'login'])->name('login');

// Thay closure bang controller, va de NGOAI moi middleware group
Route::get('/health', [HealthController::class, 'health']);
Route::get('/ping',   [HealthController::class, 'ping']);

Route::middleware(['auth:sanctum', 'ensure.active'])->group(function () {
    Route::get('/me',      [AuthController::class, 'me']);
    Route::patch('/me/profile', [AuthController::class, 'updateProfile']);
    Route::post('/me/change-password', [AuthController::class, 'changePassword']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/faculties', [ApiFacultyController::class, 'index']);
    Route::get('/departments', [ApiDepartmentController::class, 'index']);
    Route::get('/rooms', [ApiRoomController::class, 'index']);
    Route::get('/timeslots', [ApiTimeslotController::class, 'index']);
    Route::get('/timeslots/by-period', [ApiTimeslotController::class, 'getByPeriod']);

    Route::middleware('role:ADMIN')->prefix('admin')->group(function () {
        Route::get('me/profile', [AdminProfileController::class, 'show']);
        Route::patch('me/profile', [AdminProfileController::class, 'update']);
        Route::apiResource('users', UserController::class);
    });

    Route::middleware('role:DAO_TAO')->prefix('training_department')->group(function () {
        Route::get('me/profile', [TDProfileController::class, 'show']);
        Route::patch('me/profile', [TDProfileController::class, 'update']);
        Route::post('approvals/leave/{leave}', [ApprovalController::class, 'approveLeave']);
    });

    Route::middleware('role:GIANG_VIEN')->prefix('lecturer')->group(function () {

        Route::get('profile', [ProfileController::class, 'show']);

        Route::get('schedule/week', [ScheduleController::class, 'getWeekSchedule']);
        Route::get('schedule/{id}', [ScheduleController::class, 'show']);

        Route::post('schedule/{id}/report', [ReportController::class, 'store']);

        // Tai lieu buoi hoc (RESTful)
        Route::get('schedule/{id}/materials',  [MaterialController::class, 'index']);
        Route::post('schedule/{id}/materials', [MaterialController::class, 'store']);

        Route::post('leaves',   [LeaveController::class, 'store']);
        Route::get('leaves/my', [LeaveController::class, 'my']);

        // DUNG DAT /health & /ping O DAY
    });
});

// New API Lecturer group (Bearer token)
Route::prefix('lecturer')->middleware(['auth:sanctum','ensure.active','role:GIANG_VIEN'])->group(function () {
    Route::get('me/profile', [ApiLecturerProfileController::class, 'show']);
    Route::patch('me/profile', [ApiLecturerProfileController::class, 'update']);
    Route::post('me/change-password', [ApiLecturerProfileController::class, 'changePassword']);

    Route::get('schedule', [ApiLecturerScheduleController::class, 'index']);

    Route::get('sessions', [ApiTeachingSessionController::class, 'index']);
    Route::get('sessions/{id}', [ApiTeachingSessionController::class, 'show']);
    Route::patch('sessions/{id}', [ApiTeachingSessionController::class, 'update']);
    Route::post('sessions/{id}/start', [ApiTeachingSessionWorkflowController::class, 'start']);
    Route::post('sessions/{id}/finish', [ApiTeachingSessionWorkflowController::class, 'finish']);
    Route::post('sessions/{id}/end', [ApiTeachingSessionWorkflowController::class, 'end']);

    Route::get('sessions/{id}/attendance', [ApiAttendanceController::class, 'show']);
    Route::post('sessions/{id}/attendance', [ApiAttendanceController::class, 'store']);

    Route::get('leave-requests', [ApiLeaveRequestController::class, 'index']);
    Route::post('leave-requests', [ApiLeaveRequestController::class, 'store']);
    Route::get('leave-requests/{id}', [ApiLeaveRequestController::class, 'show']);
    Route::patch('leave-requests/{id}', [ApiLeaveRequestController::class, 'update']);
    Route::delete('leave-requests/{id}', [ApiLeaveRequestController::class, 'destroy']);

    Route::get('makeup-requests', [ApiMakeupRequestController::class, 'index']);
    Route::post('makeup-requests', [ApiMakeupRequestController::class, 'store']);
    Route::get('makeup-requests/{id}', [ApiMakeupRequestController::class, 'show']);
    Route::patch('makeup-requests/{id}', [ApiMakeupRequestController::class, 'update']);
    Route::delete('makeup-requests/{id}', [ApiMakeupRequestController::class, 'destroy']);

    Route::get('notifications', [ApiNotificationController::class, 'index']);
    Route::get('notifications/{id}', [ApiNotificationController::class, 'show']);
    Route::post('notifications/{id}/read', [ApiNotificationController::class, 'markRead']);
    Route::delete('notifications/{id}', [ApiNotificationController::class, 'destroy']);


    Route::get('stats/teaching-hours', [ApiStatsController::class, 'teachingHours']);
});

Route::prefix('reports')->middleware(['auth:sanctum','ensure.active'])->group(function () {
    Route::get('lecturers/{lecturer}', [ApiLecturerReportController::class, 'show'])
        ->whereNumber('lecturer');
});
