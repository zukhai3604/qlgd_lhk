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
    private array $assignmentMap = [];
    private array $timeslotCache = [];
    private array $usedPeriods = [];
    private array $rooms = [];
    private int $roomIndex = 0;
    private int $pastCounter = 0;
    private array $cancelNotes = [
        'Huy do hop giao ban',
        'Huy do bao tri phong hoc',
        'Huy theo yeu cau sinh vien',
        'Huy vi giang vien cong tac',
    ];

    public function run(): void
    {
        $this->loadAssignments();
        $this->loadRooms();

        if (empty($this->assignmentMap) || empty($this->rooms)) {
            return;
        }

        $startDate = Carbon::create(2025, 9, 1); // Monday
        $weeks = 8;
        $pivot = Carbon::create(2025, 10, 22);

        $patterns = [
            'CNW' => [
                ['day' => Carbon::MONDAY, 'session' => 'morning'],
                ['day' => Carbon::THURSDAY, 'session' => 'afternoon'],
            ],
            'CTDL' => [
                ['day' => Carbon::TUESDAY, 'session' => 'afternoon'],
                ['day' => Carbon::FRIDAY, 'session' => 'morning'],
            ],
            'CSDL' => [
                ['day' => Carbon::WEDNESDAY, 'session' => 'morning'],
                ['day' => Carbon::SATURDAY, 'session' => 'afternoon'],
            ],
        ];

        for ($week = 0; $week < $weeks; $week++) {
            foreach ($patterns as $subjectCode => $slots) {
                $assignmentId = $this->assignmentMap[$subjectCode] ?? null;
                if (!$assignmentId) {
                    $this->command?->warn("ScheduleSeeder: missing assignment for {$subjectCode}");
                    continue;
                }

                foreach ($slots as $slotIndex => $slot) {
                    $date = (clone $startDate)
                        ->addWeeks($week)
                        ->addDays($this->dayOffset($slot['day']));

                    $dateKey = $date->format('Y-m-d');
                    $periodStart = $this->pickPeriodStart($dateKey, $slot['session'], $week, $slotIndex);
                    $timeslotId = $this->resolveTimeslotId($slot['day'], $periodStart);

                    if (!$timeslotId) {
                        $this->command?->warn(sprintf(
                            'ScheduleSeeder: timeslot not found for day %d period %d',
                            $slot['day'],
                            $periodStart
                        ));
                        continue;
                    }

                    $status = $date->lt($pivot) ? $this->statusForPast() : 'PLANNED';
                    $note = $status === 'CANCELED'
                        ? $this->cancelNotes[$this->pastCounter % count($this->cancelNotes)]
                        : null;

                    Schedule::updateOrCreate(
                        [
                            'assignment_id' => $assignmentId,
                            'session_date' => $dateKey,
                            'timeslot_id' => $timeslotId,
                        ],
                        [
                            'room_id' => $this->nextRoomId(),
                            'status' => $status,
                            'note' => $note,
                            'makeup_of_id' => null,
                        ]
                    );
                }
            }
        }
    }

    private function loadAssignments(): void
    {
        $assignments = Assignment::with('subject')
            ->whereHas('subject', function ($q) {
                $q->whereIn('code', ['CNW', 'CTDL', 'CSDL']);
            })
            ->get();

        foreach ($assignments as $assignment) {
            $code = $assignment->subject?->code;
            if ($code) {
                $this->assignmentMap[$code] = $assignment->id;
            }
        }
    }

    private function loadRooms(): void
    {
        $this->rooms = Room::whereIn('code', $this->roomCodes())
            ->orderBy('code')
            ->pluck('id')
            ->toArray();

        if (empty($this->rooms)) {
            $this->command?->warn('ScheduleSeeder: no rooms found for codes A101-A120.');
        }
    }

    private function roomCodes(): array
    {
        return array_map(fn ($number) => 'A' . $number, range(101, 120));
    }

    private function nextRoomId(): int
    {
        $roomId = $this->rooms[$this->roomIndex % count($this->rooms)];
        $this->roomIndex++;
        return $roomId;
    }

    private function pickPeriodStart(string $dateKey, string $session, int $weekIndex, int $slotIndex): int
    {
        $pool = $session === 'morning'
            ? [1, 2, 3, 4, 5, 6]
            : [7, 8, 9, 10, 11, 12];

        $used = $this->usedPeriods[$dateKey][$session] ?? [];
        $count = count($pool);

        for ($i = 0; $i < $count; $i++) {
            $candidate = $pool[($weekIndex + $slotIndex + $i) % $count];
            if (!in_array($candidate, $used, true)) {
                $this->usedPeriods[$dateKey][$session][] = $candidate;
                return $candidate;
            }
        }

        throw new \RuntimeException("Unable to pick period for {$dateKey} {$session}");
    }

    private function resolveTimeslotId(int $carbonDay, int $periodStart): ?int
    {
        $timeslotDay = $carbonDay + 1; // Carbon Monday=1 -> timeslot day 2
        $code = sprintf('T%d_CA%d', $timeslotDay, $periodStart);

        if (!array_key_exists($code, $this->timeslotCache)) {
            $this->timeslotCache[$code] = Timeslot::where('code', $code)->value('id');
        }

        return $this->timeslotCache[$code];
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

    private function statusForPast(): string
    {
        $this->pastCounter++;
        return $this->pastCounter % 7 === 0 ? 'CANCELED' : 'DONE';
    }
}

