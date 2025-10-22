<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Lecturer;
use App\Models\Schedule;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class LecturerReportController extends Controller
{
    public function show(Request $request, Lecturer $lecturer): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        if ($user->role === 'GIANG_VIEN' && optional($user->lecturer)->id !== $lecturer->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $hasPeriodCount = Schema::hasColumn('schedules', 'period_count');

        $query = Schedule::query()
            ->selectRaw('subjects.id as subject_id')
            ->selectRaw('subjects.code as subject_code')
            ->selectRaw('subjects.name as subject_name')
            ->selectRaw('COUNT(*) as total_sessions')
            ->selectRaw("SUM(CASE WHEN schedules.status = 'DONE' THEN 1 ELSE 0 END) as done_sessions")
            ->selectRaw("SUM(CASE WHEN schedules.status = 'CANCELED' THEN 1 ELSE 0 END) as canceled_sessions")
            ->selectRaw("
                SUM(
                    CASE
                        WHEN schedules.status NOT IN ('DONE','CANCELED')
                        THEN 1 ELSE 0
                    END
                ) as upcoming_sessions
            ")
            ->when($hasPeriodCount, function (Builder $builder) {
                $builder->selectRaw('COALESCE(SUM(schedules.period_count), 0) as total_periods')
                    ->selectRaw("
                        COALESCE(
                            SUM(
                                CASE WHEN schedules.status = 'DONE'
                                THEN schedules.period_count END
                            ),
                            0
                        ) as done_periods
                    ");
            }, function (Builder $builder) {
                $builder->selectRaw('0 as total_periods')
                    ->selectRaw('0 as done_periods');
            })
            ->join('assignments', 'assignments.id', '=', 'schedules.assignment_id')
            ->join('subjects', 'subjects.id', '=', 'assignments.subject_id')
            ->leftJoin('class_units', 'class_units.id', '=', 'assignments.class_unit_id')
            ->leftJoin('departments', 'departments.id', '=', 'class_units.department_id')
            ->leftJoin('faculties', 'faculties.id', '=', 'departments.faculty_id')
            ->where('assignments.lecturer_id', $lecturer->id)
            ->groupBy('subjects.id', 'subjects.code', 'subjects.name')
            ->orderBy('subjects.name');

        if ($semester = $request->query('semester')) {
            $query->where('assignments.semester_label', $semester);
        }

        if ($from = $request->query('from')) {
            $query->whereDate('schedules.session_date', '>=', $from);
        }

        if ($to = $request->query('to')) {
            $query->whereDate('schedules.session_date', '<=', $to);
        }

        if ($departmentId = $request->query('department_id')) {
            $query->where('departments.id', $departmentId);
        }

        if ($facultyId = $request->query('faculty_id')) {
            $query->where('faculties.id', $facultyId);
        }

        $rows = $query->get();

        $data = $rows->map(function ($row) {
            $totalSessions = (int) $row->total_sessions;
            $doneSessions = (int) $row->done_sessions;
            $canceledSessions = (int) $row->canceled_sessions;
            $upcomingSessions = (int) $row->upcoming_sessions;

            if ($totalSessions === 0) {
                $upcomingSessions = 0;
            } else {
                $computedUpcoming = $totalSessions - ($doneSessions + $canceledSessions);
                if ($computedUpcoming !== $upcomingSessions) {
                    $upcomingSessions = $computedUpcoming;
                }
            }

            $progressRatio = $totalSessions > 0
                ? round($doneSessions / $totalSessions, 2)
                : 0.0;

            return [
                'subject_id' => (int) $row->subject_id,
                'subject_code' => $row->subject_code,
                'subject_name' => $row->subject_name,
                'total_sessions' => $totalSessions,
                'done_sessions' => $doneSessions,
                'canceled_sessions' => (int) $row->canceled_sessions,
                'upcoming_sessions' => $upcomingSessions,
                'total_periods' => (int) $row->total_periods,
                'done_periods' => (int) $row->done_periods,
                'progress_ratio' => $progressRatio,
                'progress_text' => sprintf('%d/%d buổi', $doneSessions, $totalSessions),
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'meta' => [
                'lecturer_id' => $lecturer->id,
                'filters' => [
                    'semester' => $request->query('semester'),
                    'from' => $request->query('from'),
                    'to' => $request->query('to'),
                    'department_id' => $request->query('department_id'),
                    'faculty_id' => $request->query('faculty_id'),
                ],
            ],
        ]);
    }
}

