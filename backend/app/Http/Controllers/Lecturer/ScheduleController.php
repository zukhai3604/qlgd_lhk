<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Schedule;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ScheduleController extends Controller
{
    /**
     * GET /api/lecturer/schedule/week?date=YYYY-MM-DD (optional)
     * - Mặc định: tuần hiện tại (Thứ 2 -> CN)
     * - Trả: { range: {from,to}, data: [ {id,date,start_time,end_time,subject,class_name,room,status} ] }
     */
    public function getWeekSchedule(Request $request)
    {
        // 1) Xác định tuần
        $date = Carbon::parse($request->query('date', now()->toDateString()));
        $from = $date->copy()->startOfWeek(Carbon::MONDAY)->toDateString();
        $to   = $date->copy()->endOfWeek(Carbon::SUNDAY)->toDateString();

        $userId = $request->user()->id;

        // 2) Lấy lịch tuần với các quan hệ bạn đã định nghĩa sẵn
        $schedules = Schedule::with([
                'assignment.subject:id,code,name',
                'assignment.classUnit:id,code,name',
                'timeslot:id,code,day_of_week,start_time,end_time',
                'room:id,code',
            ])
            ->whereBetween('session_date', [$from, $to])
            ->whereHas('assignment.lecturer', fn ($q) => $q->where('user_id', $userId))
            ->orderBy('session_date')
            ->orderBy('timeslot_id')
            ->get();

        // 3) Tính trạng thái cho từng buổi
        $today   = Carbon::today()->toDateString();
        $nowTime = Carbon::now()->format('H:i:s');

        $data = $schedules->map(function ($s) use ($today, $nowTime) {

            $subject   = optional($s->assignment?->subject)->name ?? ($s->subject_name ?? null);
            $className = optional($s->assignment?->classUnit)->code ?? ($s->class_name ?? null);
            $room      = $s->room->code ?? null;
            $start     = $s->timeslot->start_time ?? null;
            $end       = $s->timeslot->end_time ?? null;

            // ----- Tính status -----
            $status = 'PLANNED';

            // 3.1 Nghỉ dạy đã duyệt => CANCELED
            $hasApprovedLeave = DB::table('leave_requests')
                ->where('schedule_id', $s->id)
                ->where('status', 'APPROVED')
                ->exists();

            if ($hasApprovedLeave) {
                $status = 'CANCELED';
            } else {
                // 3.2 Đang dạy (hôm nay & trong khung giờ)
                if ($s->session_date == $today && $start && $end && $start <= $nowTime && $nowTime <= $end) {
                    $status = 'TEACHING';
                }
                // 3.3 Đã dạy xong (buổi đã qua & có báo cáo/điểm danh)
                elseif ($s->session_date < $today || ($s->session_date == $today && $end && $end < $nowTime)) {
                    $hasReport     = DB::table('session_notes')->where('schedule_id', $s->id)->exists();
                    $hasAttendance = DB::table('attendance_records')->where('schedule_id', $s->id)->exists();

                    if ($hasReport || $hasAttendance) {
                        $status = 'DONE';
                    } else {
                        // nếu muốn, vẫn để PLANNED cho buổi đã qua nhưng chưa nộp gì
                        $status = 'PLANNED';
                    }
                }
            }

            return [
                'id'         => $s->id,
                'date'       => (string) $s->session_date, // cast 'Y-m-d'
                'start_time' => $start,
                'end_time'   => $end,
                'subject'    => $subject,
                'class_name' => $className,
                'room'       => $room,
                'status'     => $status,
            ];
        });

        return response()->json([
            'range' => compact('from', 'to'),
            'data'  => $data,
        ]);
    }
}
