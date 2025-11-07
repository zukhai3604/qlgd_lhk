<?php

namespace App\Http\Controllers\Api\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use App\Models\Schedule;
use App\Models\Semester;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use OpenApi\Annotations as OA;

class ScheduleController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/schedule",
     *   operationId="lecturerScheduleIndex",
     *   tags={"Lecturer - Lịch dạy"},
     *   summary="Lấy lịch dạy trong tuần",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="semester_id",
     *     in="query",
     *     description="Mã học kỳ (ví dụ 2025-2026 HK1)",
     *     required=false,
     *     @OA\Schema(type="string")
     *   ),
     *   @OA\Parameter(
     *     name="week",
     *     in="query",
     *     description="Ngày bất kỳ trong tuần muốn lấy (YYYY-MM-DD)",
     *     required=false,
     *     @OA\Schema(type="string", format="date")
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách buổi dạy theo tuần",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/ScheduleItem")),
     *       @OA\Property(
     *         property="filters",
     *         type="object",
     *         @OA\Property(
     *           property="semesters",
     *           type="array",
     *           @OA\Items(
     *             type="object",
     *             @OA\Property(property="value", type="string"),
     *             @OA\Property(property="label", type="string")
     *           )
     *         ),
     *         @OA\Property(
     *           property="weeks",
     *           type="array",
     *           @OA\Items(
     *             type="object",
     *             @OA\Property(property="value", type="string"),
     *             @OA\Property(property="label", type="string"),
     *             @OA\Property(property="start", type="string"),
     *             @OA\Property(property="end", type="string")
     *           )
     *         ),
     *         @OA\Property(property="selected_semester", type="string", nullable=true),
     *         @OA\Property(property="selected_week", type="string", nullable=true),
     *         @OA\Property(property="week_start", type="string", nullable=true),
     *         @OA\Property(property="week_end", type="string", nullable=true)
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=403,
     *     description="Không phải giảng viên",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        if (!$lecturerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $semesterFilter = $request->query('semester_id');
        $weekFilter = $request->query('week');

        // Xác định semesterFilter TRƯỚC khi tạo baseQuery
        $semesterOptions = $this->buildSemesterOptions($lecturerId);
        
        // Nếu không có semesterFilter, tìm semester đầu tiên mà lecturer CÓ assignment
        if (!$semesterFilter) {
            $lecturerSemesterIds = Assignment::query()
                ->select('semester_id')
                ->where('lecturer_id', $lecturerId)
                ->whereNotNull('semester_id')
                ->distinct()
                ->pluck('semester_id')
                ->toArray();
            
            // Tìm semester đầu tiên trong danh sách mà lecturer có assignment
            foreach ($semesterOptions as $semester) {
                if (in_array((int)$semester['value'], $lecturerSemesterIds)) {
                    $semesterFilter = $semester['value'];
                    break;
                }
            }
        }
        
        $selectedSemester = $semesterFilter ?: ($semesterOptions->first()['value'] ?? null);
        
        // Convert selectedSemester sang string để Flutter parse đúng
        $selectedSemester = $selectedSemester !== null ? (string) $selectedSemester : null;

        // Tạo baseQuery SAU khi đã xác định semesterFilter
        $baseQuery = Schedule::query()
            ->with([
                'assignment.subject',
                'assignment.classUnit',
                'assignment.semester',
                'room',
                'timeslot',
            ])
            ->whereHas('assignment', function ($query) use ($lecturerId, $semesterFilter) {
                $query->where('lecturer_id', $lecturerId);
                if ($semesterFilter) {
                    $query->where('semester_id', $semesterFilter);
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
        // Lấy TẤT CẢ semesters có trong hệ thống, sắp xếp theo start_date giảm dần
        // (thay vì chỉ lấy từ assignments của lecturer)
        $semesters = Semester::query()
            ->orderBy('start_date', 'desc')
            ->get();
        
        return $semesters->map(fn($semester) => [
            'value' => (string) $semester->id, // Convert sang string để Flutter parse đúng
            'label' => $semester->name,
            'code' => $semester->code,
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
                'semester_id' => $assignment->semester_id,
                'semester' => $assignment->semester ? [
                    'id' => $assignment->semester->id,
                    'code' => $assignment->semester->code,
                    'name' => $assignment->semester->name,
                ] : null,
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
