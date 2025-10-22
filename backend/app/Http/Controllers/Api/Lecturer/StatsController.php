<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StatsController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/stats/teaching-hours",
     *   tags={"Lecturer"},
     *   summary="Thống kê giờ giảng",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK")
     * )
     */
    public function teachingHours(Request $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $from = $request->query('from');
        $to = $request->query('to');

        $q = Schedule::query()
            ->select('schedules.*')
            ->join('assignments','assignments.id','=','schedules.assignment_id')
            ->where('assignments.lecturer_id', $lecId)
            ->where('schedules.status','DONE')
            ->join('timeslots','timeslots.id','=','schedules.timeslot_id');

        if ($from) $q->whereDate('schedules.session_date','>=',$from);
        if ($to) $q->whereDate('schedules.session_date','<=',$to);

        $rows = $q->get(['schedules.id','schedules.session_date','timeslots.start_time','timeslots.end_time']);
        $totalSessions = $rows->count();
        $totalHours = 0.0;
        foreach ($rows as $r) {
            $start = strtotime($r->start_time);
            $end = strtotime($r->end_time);
            $totalHours += max(0, ($end - $start) / 3600);
        }

        $all = Schedule::query()
            ->join('assignments','assignments.id','=','schedules.assignment_id')
            ->where('assignments.lecturer_id', $lecId);
        if ($from) $all->whereDate('schedules.session_date','>=',$from);
        if ($to) $all->whereDate('schedules.session_date','<=',$to);
        $countsByStatus = $all->select('schedules.status', DB::raw('count(*) as c'))
            ->groupBy('schedules.status')->pluck('c','schedules.status');

        return response()->json([
            'data' => [
                'total_sessions_done' => $totalSessions,
                'total_hours' => round($totalHours, 2),
                'by_status' => $countsByStatus,
            ]
        ]);
    }
}

