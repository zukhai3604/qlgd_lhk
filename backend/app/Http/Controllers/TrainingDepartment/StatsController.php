<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use App\Models\Room;
use App\Models\Schedule;

class StatsController extends Controller
{
    /**
     * Quick realtime-ish stats for Training Department home.
     * - lecturers_teaching_now: distinct lecturers teaching at this moment
     * - rooms_in_use_now: distinct rooms in use at this moment
     * - rooms_free_now: total rooms - in use
     * - pending_requests_total: PENDING leave + makeup
     */
    public function quick()
    {
        $today = now()->toDateString();
        $nowTime = now()->format('H:i:s');

        // Active schedules at current time (exclude canceled)
        $activeSchedules = Schedule::query()
            ->with(['assignment', 'assignment.lecturer', 'room', 'timeslot'])
            ->whereDate('session_date', $today)
            ->whereNotIn('status', ['CANCELED'])
            ->whereHas('timeslot', function ($q) use ($nowTime) {
                $q->where('start_time', '<=', $nowTime)
                  ->where('end_time', '>', $nowTime);
            })
            ->get();

        $lecturersNow = $activeSchedules
            ->pluck('assignment.lecturer_id')
            ->filter()
            ->unique()
            ->count();

        $roomsInUse = $activeSchedules
            ->pluck('room_id')
            ->filter()
            ->unique()
            ->count();

        $roomsTotal = Room::count();
        $roomsFree = max(0, $roomsTotal - $roomsInUse);

        $pendingLeave = LeaveRequest::where('status', 'PENDING')->count();
        $pendingMakeup = MakeupRequest::where('status', 'PENDING')->count();

        return response()->json([
            'data' => [
                'lecturers_teaching_now' => $lecturersNow,
                'rooms_in_use_now'       => $roomsInUse,
                'rooms_free_now'         => $roomsFree,
                'pending_requests_total' => $pendingLeave + $pendingMakeup,
            ],
        ]);
    }
}
