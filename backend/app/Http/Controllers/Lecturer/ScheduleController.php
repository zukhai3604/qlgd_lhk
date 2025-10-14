<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Schedule;
use Carbon\Carbon;

class ScheduleController extends Controller
{
    public function getWeekSchedule(Request $request)
    {
        $date   = Carbon::parse($request->query('date', now()->toDateString()));
        $from   = $date->copy()->startOfWeek(Carbon::MONDAY)->toDateString();
        $to     = $date->copy()->endOfWeek(Carbon::SUNDAY)->toDateString();

        $user = $request->user();

        $data = Schedule::with([
                'assignment.subject:id,code,name',
                'assignment.classUnit:id,code,name',
                'timeslot:id,code,day_of_week,start_time,end_time',
                'room:id,code'
            ])
            ->whereBetween('session_date', [$from, $to])
            ->whereHas('assignment.lecturer', fn($q)=>$q->where('user_id',$user->id))
            ->orderBy('session_date')->get();

        return response()->json(['range'=>compact('from','to'),'data'=>$data]);
    }
}
