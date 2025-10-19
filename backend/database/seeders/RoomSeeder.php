<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Room;

class RoomSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $rooms = [
            [
                'code' => 'B5-207',
                'building' => 'B5',
                'capacity' => 80,
                'room_type' => 'LT' // Sửa từ 'THEORY' thành 'LT' (Lý thuyết)
            ],
            [
                'code' => 'B5-210',
                'building' => 'B5',
                'capacity' => 80,
                'room_type' => 'LT'
            ],
            [
                'code' => 'A2-301',
                'building' => 'A2',
                'capacity' => 40,
                'room_type' => 'TH' // Sửa từ 'PRACTICE' thành 'TH' (Thực hành)
            ],
            [
                'code' => 'C1-404',
                'building' => 'C1',
                'capacity' => 100,
                'room_type' => 'OTHER' // Sửa từ 'HALL' thành 'OTHER' (Khác)
            ],
        ];

        // Dùng vòng lặp để tạo hoặc cập nhật từng phòng
        foreach ($rooms as $room) {
            Room::updateOrCreate(
                ['code' => $room['code']],
                $room
            );
        }
    }
}
