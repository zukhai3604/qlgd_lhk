<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use App\Models\Schedule;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class ScheduleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        if (!$lecturerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $semesterFilter = $request->query('semester_id');
        $weekFilter = $request->query('week');

        $baseQuery = Schedule::query()
            ->with([
                'assignment.subject',
                'assignment.classUnit',
                'room',
                'timeslot',
            ])
            ->whereHas('assignment', function ($query) use ($lecturerId, $semesterFilter) {
                $query->where('lecturer_id', $lecturerId);
                if ($semesterFilter) {
                    $query->where('semester_label', $semesterFilter);
                }
            });

        $allDates = (clone $baseQuery)
            ->select('session_date')
            ->distinct()
            ->orderBy('session_date')
            ->pluck('session_date');

        $weekOptions = $this->buildWeekOptions($allDates);

        [$weekStart, $weekEnd, $selectedWeek] = $this->resolveWeekWindow(
            $weekOptions,
            $weekFilter
        );

        $semesterOptions = $this->buildSemesterOptions($lecturerId);
        $selectedSemester = $semesterFilter ?: ($semesterOptions->first()['value'] ?? null);

        $items = (clone $baseQuery)
            ->when(
                $weekStart && $weekEnd,
                fn($query) => $query->whereBetween('session_date', [
                    $weekStart->toDateString(),
                    $weekEnd->toDateString(),
                ])
            )
            ->orderBy('session_date')
            ->orderBy('timeslot_id')
            ->get()
            ->map(fn(Schedule $schedule) => $this->transformSchedule($schedule));

        return response()->json([
            'data' => $items,
            'filters' => [
                'semesters' => $semesterOptions->values()->all(),
                'weeks' => $weekOptions->values()->all(),
                'selected_semester' => $selectedSemester,
                'selected_week' => $selectedWeek,
                'week_start' => $weekStart?->toDateString(),
                'week_end' => $weekEnd?->toDateString(),
            ],
        ]);
    }

    private function buildWeekOptions(Collection $dates): Collection
    {
        $options = [];
        foreach ($dates as $date) {
            if (!$date) {
                continue;
            }
            $start = Carbon::parse($date)->startOfWeek(Carbon::MONDAY);
            $end = (clone $start)->endOfWeek(Carbon::SUNDAY);
            $key = $start->toDateString();

            $options[$key] = [
                'value' => $key,
                'label' => sprintf(
                    '%s - %s',
                    $start->format('d/m/Y'),
                    $end->format('d/m/Y')
                ),
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ];
        }

        return collect($options)
            ->sortBy('start')
            ->values();
    }

    private function resolveWeekWindow(Collection $options, ?string $requested): array
    {
        $weekStart = null;
        $weekEnd = null;
        $selected = null;

        $lookup = $options->keyBy('value');

        if ($requested) {
            $candidate = Carbon::parse($requested)->startOfWeek(Carbon::MONDAY);
            $selectedOption = $lookup->get($candidate->toDateString());
            if ($selectedOption) {
                $weekStart = Carbon::parse($selectedOption['start'])->startOfDay();
                $weekEnd = Carbon::parse($selectedOption['end'])->endOfDay();
                $selected = $selectedOption['value'];
            }
        }

        if (!$weekStart && !$weekEnd && $lookup->isNotEmpty()) {
            $today = Carbon::now()->startOfWeek(Carbon::MONDAY);

            $selectedOption = $lookup->first(
                fn(array $option) => $today->betweenIncluded(
                    Carbon::parse($option['start'])->startOfDay(),
                    Carbon::parse($option['end'])->endOfDay()
                )
            ) ?: $lookup->first();

            if ($selectedOption) {
                $weekStart = Carbon::parse($selectedOption['start'])->startOfDay();
                $weekEnd = Carbon::parse($selectedOption['end'])->endOfDay();
                $selected = $selectedOption['value'];
            }
        }

        if (!$weekStart || !$weekEnd) {
            $weekStart = Carbon::now()->startOfWeek(Carbon::MONDAY);
            $weekEnd = (clone $weekStart)->endOfWeek(Carbon::SUNDAY);
            $selected ??= $weekStart->toDateString();
        }

        return [$weekStart, $weekEnd, $selected];
    }

    private function buildSemesterOptions(int $lecturerId): Collection
    {
        $semesters = Assignment::query()
            ->select('semester_label')
            ->where('lecturer_id', $lecturerId)
            ->whereNotNull('semester_label')
            ->distinct()
            ->orderBy('semester_label')
            ->pluck('semester_label');

        return $semesters->map(fn($label) => [
            'value' => $label,
            'label' => $label,
        ]);
    }

    private function transformSchedule(Schedule $schedule): array
    {
        $timeslot = $schedule->timeslot;
        $room = $schedule->room;
        $assignment = $schedule->assignment;
        $subject = $assignment?->subject;
        $classUnit = $assignment?->classUnit;

        return [
            'id' => $schedule->id,
            'session_date' => $schedule->session_date?->format('Y-m-d'),
            'status' => $schedule->status,
            'note' => $schedule->note,
            'start_time' => $timeslot?->start_time,
            'end_time' => $timeslot?->end_time,
            'timeslot' => $timeslot ? [
                'id' => $timeslot->id,
                'code' => $timeslot->code,
                'day_of_week' => $timeslot->day_of_week,
                'start_time' => $timeslot->start_time,
                'end_time' => $timeslot->end_time,
            ] : null,
            'room' => $room ? [
                'id' => $room->id,
                'code' => $room->code,
                'name' => $room->code ?? $room->building,
            ] : null,
            'assignment' => $assignment ? [
                'id' => $assignment->id,
                'semester_label' => $assignment->semester_label,
                'subject' => $subject ? [
                    'id' => $subject->id,
                    'code' => $subject->code,
                    'name' => $subject->name,
                ] : null,
                'classUnit' => $classUnit ? [
                    'id' => $classUnit->id,
                    'code' => $classUnit->code,
                    'name' => $classUnit->name,
                ] : null,
            ] : null,
        ];
    }
}
