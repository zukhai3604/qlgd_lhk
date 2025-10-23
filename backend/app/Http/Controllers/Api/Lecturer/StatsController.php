<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use OpenApi\Annotations as OA;

class StatsController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/stats/teaching-hours",
     *   operationId="lecturerStatsTeachingHours",
     *   tags={"Lecturer - Thống kê"},
     *   summary="Thống kê số buổi và giờ giảng đã hoàn thành",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="from",
     *     in="query",
     *     description="Ngày bắt đầu (YYYY-MM-DD)",
     *     @OA\Schema(type="string", format="date")
     *   ),
     *   @OA\Parameter(
     *     name="to",
     *     in="query",
     *     description="Ngày kết thúc (YYYY-MM-DD)",
     *     @OA\Schema(type="string", format="date")
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Thống kê tổng quan",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", type="object",
     *         @OA\Property(property="total_sessions_done", type="integer", example=48),
     *         @OA\Property(property="total_hours", type="number", format="float", example=120.5),
     *         @OA\Property(
     *           property="by_status",
     *           type="object",
     *           @OA\AdditionalProperties(
     *             type="integer",
     *             description="Số buổi theo từng trạng thái"
     *           )
     *         )
     *       )
     *     )
     *   )
     * )
     */
    public function teachingHours(Request $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        $from = $request->query('from');
        $to = $request->query('to');

        $query = Schedule::query()
            ->select('schedules.*')
            ->join('assignments', 'assignments.id', '=', 'schedules.assignment_id')
            ->where('assignments.lecturer_id', $lecturerId)
            ->where('schedules.status', 'DONE')
            ->join('timeslots', 'timeslots.id', '=', 'schedules.timeslot_id');

        if ($from) {
            $query->whereDate('schedules.session_date', '>=', $from);
        }
        if ($to) {
            $query->whereDate('schedules.session_date', '<=', $to);
        }

        $rows = $query->get(['schedules.id', 'schedules.session_date', 'timeslots.start_time', 'timeslots.end_time']);

        $totalSessions = $rows->count();
        $totalHours = 0.0;
        foreach ($rows as $row) {
            $start = strtotime($row->start_time);
            $end = strtotime($row->end_time);
            $totalHours += max(0, ($end - $start) / 3600);
        }

        $all = Schedule::query()
            ->join('assignments', 'assignments.id', '=', 'schedules.assignment_id')
            ->where('assignments.lecturer_id', $lecturerId);

        if ($from) {
            $all->whereDate('schedules.session_date', '>=', $from);
        }
        if ($to) {
            $all->whereDate('schedules.session_date', '<=', $to);
        }

        $countsByStatus = $all->select('schedules.status', DB::raw('count(*) as total'))
            ->groupBy('schedules.status')
            ->pluck('total', 'schedules.status');

        return response()->json([
            'data' => [
                'total_sessions_done' => $totalSessions,
                'total_hours' => round($totalHours, 2),
                'by_status' => $countsByStatus,
            ],
        ]);
    }
}
