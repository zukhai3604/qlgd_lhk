<?php
namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

/** @OA\Tag(name="Lecturer - Schedule", description="Lich day") */
class ScheduleController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/schedule/week",
     *   tags={"Lecturer - Schedule"},
     *   summary="Lich day theo tuan",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="date", in="query", required=false, @OA\Schema(type="string", format="date")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function getWeekSchedule(Request $request)
    {
        $user = $request->user();
        $lecturer = $user?->lecturer;
        if (!$lecturer) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $date = $request->query('date');
        $base = $date ? \Carbon\Carbon::parse($date) : now();
        $start = (clone $base)->startOfWeek(1)->toDateString();
        $end   = (clone $base)->endOfWeek(0)->toDateString();

        $items = \App\Models\Schedule::query()
            ->with(['assignment.subject','assignment.classUnit','timeslot','room'])
            ->whereHas('assignment', fn($q) => $q->where('lecturer_id', $lecturer->id))
            ->whereBetween('session_date', [$start, $end])
            ->orderBy('session_date')
            ->get();

        $data = $items->map(function($s){
            $a = $s->assignment;
            return [
                'id' => $s->id,
                'session_date' => optional($s->session_date)->format('Y-m-d'),
                'status' => $s->status,
                'note' => $s->note,
                'timeslot' => $s->timeslot ? [
                    'id' => $s->timeslot->id,
                    'code' => $s->timeslot->code,
                    'start_time' => $s->timeslot->start_time,
                    'end_time' => $s->timeslot->end_time,
                ] : null,
                'room' => $s->room ? [
                    'id' => $s->room->id,
                    'code' => $s->room->code ?? null,
                    'name' => $s->room->code ?? $s->room->building ?? '',
                ] : null,
                'assignment' => $a ? [
                    'id' => $a->id,
                    'subject' => $a->subject ? [
                        'id' => $a->subject->id,
                        'code' => $a->subject->code,
                        'name' => $a->subject->name,
                    ] : null,
                    'classUnit' => $a->classUnit ? [
                        'id' => $a->classUnit->id,
                        'code' => $a->classUnit->code ?? null,
                        'name' => $a->classUnit->name ?? null,
                    ] : null,
                ] : null,
            ];
        })->values();

        return response()->json($data);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/schedule/{id}",
     *   tags={"Lecturer - Schedule"},
     *   summary="Chi tiet buoi hoc",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=404, description="Not Found")
     * )
     */
    public function show($id)
    {
        $s = \App\Models\Schedule::with(['assignment.subject','assignment.classUnit','timeslot','room'])->find($id);
        if (!$s) return response()->json(['message' => 'Not Found'], 404);
        $a = $s->assignment;
        $data = [
            'id' => $s->id,
            'session_date' => optional($s->session_date)->format('Y-m-d'),
            'status' => $s->status,
            'note' => $s->note,
            'timeslot' => $s->timeslot ? [
                'id' => $s->timeslot->id,
                'code' => $s->timeslot->code,
                'start_time' => $s->timeslot->start_time,
                'end_time' => $s->timeslot->end_time,
            ] : null,
            'room' => $s->room ? [
                'id' => $s->room->id,
                'code' => $s->room->code ?? null,
                'name' => $s->room->code ?? $s->room->building ?? '',
            ] : null,
            'assignment' => $a ? [
                'id' => $a->id,
                'subject' => $a->subject ? [
                    'id' => $a->subject->id,
                    'code' => $a->subject->code,
                    'name' => $a->subject->name,
                ] : null,
                'classUnit' => $a->classUnit ? [
                    'id' => $a->classUnit->id,
                    'code' => $a->classUnit->code ?? null,
                    'name' => $a->classUnit->name ?? null,
                ] : null,
            ] : null,
        ];
        return response()->json($data);
    }
}

