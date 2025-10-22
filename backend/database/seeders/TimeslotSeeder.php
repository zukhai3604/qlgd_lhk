<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Timeslot;
use Carbon\Carbon;

class TimeslotSeeder extends Seeder
{
    public function run(): void
    {
        // --- Sinh 15 tiết trong ngày theo quy tắc 50' + 5', ngoại lệ 12:25→12:55 và 18:20→18:50
        $dailySlots = $this->generateDailySlots(15);

        // 2=Mon ... 7=Sat (nếu cần CN thì thêm 8 với prefix 'CN')
        $daysOfWeek = [
            ['day' => 2, 'prefix' => 'T2'],
            ['day' => 3, 'prefix' => 'T3'],
            ['day' => 4, 'prefix' => 'T4'],
            ['day' => 5, 'prefix' => 'T5'],
            ['day' => 6, 'prefix' => 'T6'],
            ['day' => 7, 'prefix' => 'T7'],
        ];

        foreach ($daysOfWeek as $dayInfo) {
            foreach ($dailySlots as $slot) {
                $code = $dayInfo['prefix'] . '_CA' . $slot['code_suffix']; // ví dụ: T2_CA1

                Timeslot::updateOrCreate(
                    ['code' => $code],
                    [
                        'day_of_week' => $dayInfo['day'],
                        'start_time'  => $slot['start_time'],
                        'end_time'    => $slot['end_time'],
                    ]
                );
            }
        }
    }

    /**
     * Sinh N tiết trong ngày bắt đầu từ 07:00
     * - Mỗi tiết 50', nghỉ 5'
     * - Ngoại lệ: nếu end == 12:25 → next start = 12:55; end == 18:20 → next start = 18:50
     */
    private function generateDailySlots(int $count = 13): array
    {
        $slots = [];
        $start = Carbon::createFromTime(7, 0, 0); // 07:00

        for ($i = 1; $i <= $count; $i++) {
            $end = (clone $start)->addMinutes(50);

            $slots[] = [
                'code_suffix' => (string)$i,
                'start_time'  => $start->format('H:i:s'),
                'end_time'    => $end->format('H:i:s'),
            ];

            // nghỉ mặc định 5'
            $nextStart = (clone $end)->addMinutes(5);

            // ngoại lệ nghỉ dài
            if ($end->format('H:i') === '12:25') {
                $nextStart = (clone $end)->addMinutes(30); // 12:55
            } elseif ($end->format('H:i') === '18:20') {
                $nextStart = (clone $end)->addMinutes(30); // 18:50
            }

            $start = $nextStart;
        }

        return $slots;
    }
}
