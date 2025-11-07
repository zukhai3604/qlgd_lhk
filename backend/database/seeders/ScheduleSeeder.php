<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Assignment;
use App\Models\Room;
use App\Models\Schedule;
use App\Models\Timeslot;
use Carbon\Carbon;

class ScheduleSeeder extends Seeder
{
    private Carbon $startDate;
    private int $weeks = 8;
    private Carbon $pivotDate;

    private array $roomIds = [];
    private int $roomIndex = 0;
    private array $timeslotCache = [];

    private array $globalSlotPool = [];
    private array $takenGlobalTimes = [];
    private array $lecturerTimes = [];

    private int $pastCounter = 0;

    private array $cancelNotes = [
        'Huy do hop giao ban',
        'Huy do bao tri phong hoc',
        'Huy theo yeu cau sinh vien',
        'Huy vi giang vien cong tac',
    ];

    public function __construct()
    {
        $this->startDate = Carbon::create(2025, 11, 1)->startOfWeek(Carbon::MONDAY);
        $this->pivotDate = Carbon::create(2025, 10, 22)->startOfDay();
    }

    public function run(): void
    {
        $assignments = Assignment::with(['subject', 'lecturer.user'])->get();
        if ($assignments->isEmpty()) {
            $this->command?->warn('ScheduleSeeder: khong tim thay assignment nao.');
            return;
        }

        $this->roomIds = Room::orderBy('code')->pluck('id')->all();
        if (empty($this->roomIds)) {
            $this->command?->warn('ScheduleSeeder: khong co phong hoc kha dung.');
            return;
        }

        $this->ensureGlobalSlotPool();

        foreach ($assignments as $assignment) {
            $lecturer = $assignment->lecturer;
            if (!$lecturer || !$assignment->subject) {
                $this->command?->warn(sprintf(
                    'ScheduleSeeder: bo qua assignment #%d vi thieu giang vien hoac mon hoc.',
                    $assignment->id
                ));
                continue;
            }

            try {
                $slot = $this->reserveSlotPairForAssignment($lecturer->id);
            } catch (\RuntimeException $e) {
                $this->command?->warn($e->getMessage());
                continue;
            }

            $day = $slot['day'];
            $startPeriod = $slot['start_period'];

            for ($week = 0; $week < $this->weeks; $week++) {
                $date = $this->dateForWeek($week, $day);
                [$status, $note] = $this->statusForDate($date);
                $roomId = $this->nextRoomId();

                for ($offset = 0; $offset < 2; $offset++) {
                    $period = $startPeriod + $offset;
                    $timeslotId = $this->resolveTimeslotId($day, $period);

                    if (!$timeslotId) {
                        $this->command?->warn(sprintf(
                            'ScheduleSeeder: khong tim thay timeslot cho day=%d period=%d.',
                            $day,
                            $period
                        ));
                        continue;
                    }

                    Schedule::updateOrCreate(
                        [
                            'assignment_id' => $assignment->id,
                            'session_date' => $date->toDateString(),
                            'timeslot_id' => $timeslotId,
                        ],
                        [
                            'room_id' => $roomId,
                            'status' => $status,
                            'note' => $note,
                            'makeup_of_id' => null,
                        ]
                    );
                }
            }
        }
    }

    private function reserveSlotPairForAssignment(int $lecturerId): array
    {
        foreach ($this->globalSlotPool as $index => $slot) {
            if (!$this->canUseSlotPair($lecturerId, $slot)) {
                continue;
            }

            $this->markSlotPair($lecturerId, $slot);
            unset($this->globalSlotPool[$index]);
            $this->globalSlotPool = array_values($this->globalSlotPool);

            return $slot;
        }

        throw new \RuntimeException("ScheduleSeeder: khong du khung thoi gian cho giang vien #{$lecturerId}.");
    }

    private function canUseSlotPair(int $lecturerId, array $slot): bool
    {
        $day = $slot['day'];
        $start = $slot['start_period'];
        $second = $start + 1;

        if ($second > 12) {
            return false;
        }

        if (($this->takenGlobalTimes[$day][$start] ?? false) ||
            ($this->takenGlobalTimes[$day][$second] ?? false)) {
            return false;
        }

        if (($this->lecturerTimes[$lecturerId][$day][$start] ?? false) ||
            ($this->lecturerTimes[$lecturerId][$day][$second] ?? false)) {
            return false;
        }

        return true;
    }

    private function markSlotPair(int $lecturerId, array $slot): void
    {
        $day = $slot['day'];
        $start = $slot['start_period'];
        $second = $start + 1;

        $this->takenGlobalTimes[$day][$start] = true;
        $this->takenGlobalTimes[$day][$second] = true;

        $this->lecturerTimes[$lecturerId][$day][$start] = true;
        $this->lecturerTimes[$lecturerId][$day][$second] = true;
    }

    private function ensureGlobalSlotPool(): void
    {
        if (!empty($this->globalSlotPool)) {
            return;
        }

        $days = [
            Carbon::MONDAY,
            Carbon::TUESDAY,
            Carbon::WEDNESDAY,
            Carbon::THURSDAY,
            Carbon::FRIDAY,
            Carbon::SATURDAY,
        ];

        foreach ($days as $day) {
            foreach (range(1, 11) as $start) {
                $this->globalSlotPool[] = [
                    'day' => $day,
                    'start_period' => $start,
                ];
            }
        }

        shuffle($this->globalSlotPool);
    }

    private function resolveTimeslotId(int $carbonDay, int $period): ?int
    {
        $timeslotDay = $carbonDay + 1; // Carbon Monday=1 -> timeslot day 2
        $code = sprintf('T%d_CA%d', $timeslotDay, $period);

        if (!array_key_exists($code, $this->timeslotCache)) {
            $this->timeslotCache[$code] = Timeslot::where('code', $code)->value('id');
        }

        return $this->timeslotCache[$code];
    }

    private function dateForWeek(int $week, int $carbonDay): Carbon
    {
        $weekStart = (clone $this->startDate)->addWeeks($week);
        return $weekStart->copy()->startOfWeek(Carbon::MONDAY)->addDays($this->dayOffset($carbonDay));
    }

    private function dayOffset(int $carbonDay): int
    {
        $map = [
            Carbon::MONDAY => 0,
            Carbon::TUESDAY => 1,
            Carbon::WEDNESDAY => 2,
            Carbon::THURSDAY => 3,
            Carbon::FRIDAY => 4,
            Carbon::SATURDAY => 5,
            Carbon::SUNDAY => 6,
        ];

        return $map[$carbonDay] ?? 0;
    }

    private function nextRoomId(): int
    {
        $roomId = $this->roomIds[$this->roomIndex % count($this->roomIds)];
        $this->roomIndex++;
        return $roomId;
    }

    private function statusForDate(Carbon $date): array
    {
        // Tất cả schedules trước ngày hôm nay đều là DONE
        if ($date->lt(Carbon::today())) {
            $this->pastCounter++;
            // Một số ít có thể là CANCELED (10% để test)
            if ($this->pastCounter % 10 === 0) {
                return ['CANCELED', $this->cancelNotes[array_rand($this->cancelNotes)]];
            }
            return ['DONE', null];
        }

        return ['PLANNED', null];
    }
}
