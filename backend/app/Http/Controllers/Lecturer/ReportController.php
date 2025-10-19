<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\LessonReportRequest;
use App\Models\Schedule;
use App\Models\SessionNote;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function store(LessonReportRequest $request, $id)
    {
        $schedule = Schedule::with('assignment.lecturer')->findOrFail($id);

        // chỉ cho giảng viên sở hữu nộp báo cáo
        abort_if(
            !$schedule->assignment || !$schedule->assignment->lecturer
            || $schedule->assignment->lecturer->user_id !== $request->user()->id,
            403, 'Không có quyền.'
        );

        DB::transaction(function () use ($request, $schedule) {
            SessionNote::create([
                'schedule_id' => $schedule->id,
                'user_id'     => $request->user()->id,
                'content'     => $request->input('content'),
                'issues'      => $request->input('issues'),
                'next_plan'   => $request->input('next_plan'),
            ]);

            // nếu có cột status trong schedules
            if (\Schema::hasColumn('schedules', 'status')) {
                $schedule->update(['status' => 'DONE']);
            }
        });

        return response()->json(['message' => 'Đã lưu báo cáo buổi học.']);
    }
}
