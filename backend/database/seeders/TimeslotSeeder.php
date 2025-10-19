<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Timeslot;

class TimeslotSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run(): void
    {
        // Định nghĩa các ca học chuẩn trong ngày
        $dailySlots = [
            ['code_suffix' => '1', 'start_time' => '07:00:00', 'end_time' => '09:00:00'], // Ca 1
            ['code_suffix' => '2', 'start_time' => '09:10:00', 'end_time' => '11:10:00'], // Ca 2
            ['code_suffix' => '3', 'start_time' => '12:30:00', 'end_time' => '14:30:00'], // Ca 3
            ['code_suffix' => '4', 'start_time' => '14:40:00', 'end_time' => '16:40:00'], // Ca 4
            ['code_suffix' => '5', 'start_time' => '16:50:00', 'end_time' => '18:50:00'], // Ca 5
        ];

        // Định nghĩa các ngày trong tuần
        // 2: Thứ Hai, 3: Thứ Ba, ..., 7: Thứ Bảy, 8: Chủ Nhật
        $daysOfWeek = [
            ['day' => 2, 'prefix' => 'T2'], // Thứ Hai
            ['day' => 3, 'prefix' => 'T3'], // Thứ Ba
            ['day' => 4, 'prefix' => 'T4'], // Thứ Tư
            ['day' => 5, 'prefix' => 'T5'], // Thứ Năm
            ['day' => 6, 'prefix' => 'T6'], // Thứ Sáu
            ['day' => 7, 'prefix' => 'T7'], // Thứ Bảy
        ];

        // Dùng vòng lặp để tạo dữ liệu cho cả tuần
        foreach ($daysOfWeek as $dayInfo) {
            foreach ($dailySlots as $slotInfo) {
                // Tạo mã ca học, ví dụ: "T2_CA1", "T3_CA2"
                $code = $dayInfo['prefix'] . '_CA' . $slotInfo['code_suffix'];

                Timeslot::updateOrCreate(
                    ['code' => $code], // Khóa để kiểm tra
                    [
                        'day_of_week' => $dayInfo['day'],
                        'start_time'  => $slotInfo['start_time'],
                        'end_time'    => $slotInfo['end_time'],
                    ]
                );
            }
        }
    }
}
