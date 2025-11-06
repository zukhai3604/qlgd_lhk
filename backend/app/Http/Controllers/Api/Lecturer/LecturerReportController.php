<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Lecturer;
use App\Models\Schedule;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use OpenApi\Annotations as OA;

class LecturerReportController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/reports/lecturers/{lecturer}",
     *   operationId="lecturerReportsShow",
     *   tags={"Lecturer - Báo cáo"},
     *   summary="Thống kê tiến độ giảng dạy theo môn học",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="lecturer", in="path", required=true, @OA\Schema(type="integer", example=7)),
     *   @OA\Parameter(name="semester", in="query", @OA\Schema(type="string", example="2025-2026 HK1")),
     *   @OA\Parameter(name="from", in="query", @OA\Schema(type="string", format="date", example="2025-09-01")),
     *   @OA\Parameter(name="to", in="query", @OA\Schema(type="string", format="date", example="2025-12-31")),
     *   @OA\Parameter(name="department_id", in="query", @OA\Schema(type="integer")),
     *   @OA\Parameter(name="faculty_id", in="query", @OA\Schema(type="integer")),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách thống kê theo môn học",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="subject_id", type="integer", example=12),
     *           @OA\Property(property="subject_code", type="string", example="CT101"),
     *           @OA\Property(property="subject_name", type="string", example="Cấu trúc dữ liệu"),
     *           @OA\Property(property="total_sessions", type="integer", example=30),
     *           @OA\Property(property="done_sessions", type="integer", example=24),
     *           @OA\Property(property="canceled_sessions", type="integer", example=1),
     *           @OA\Property(property="upcoming_sessions", type="integer", example=5),
     *           @OA\Property(property="total_periods", type="integer", example=60),
     *           @OA\Property(property="done_periods", type="integer", example=48),
     *           @OA\Property(property="progress_ratio", type="number", format="float", example=0.8),
     *           @OA\Property(property="progress_text", type="string", example="24/30 buoi")
     *         )
     *       ),
     *       @OA\Property(property="meta", type="object")
     *     )
     *   ),
     *   @OA\Response(response=401, description="Chưa xác thực", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
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
            $query->join('semesters', 'semesters.id', '=', 'assignments.semester_id')
                ->where(function ($q) use ($semester) {
                    $q->where('semesters.code', $semester)
                      ->orWhere('semesters.name', $semester);
                });
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
                'progress_text' => sprintf('%d/%d buoi', $doneSessions, $totalSessions),
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
