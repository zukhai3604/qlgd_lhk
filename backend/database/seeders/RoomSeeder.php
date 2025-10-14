<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Room;

class RoomSeeder extends Seeder
{
    public function run(): void
    {
        Room::updateOrCreate(
            ['code' => 'B5-207'],
            ['building' => 'B5','capacity' => 80,'room_type' => 'LT']
        );
    }
}
