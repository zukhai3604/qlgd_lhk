<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Timeslot;

class TimeslotSeeder extends Seeder
{
    public function run(): void
    {
        $slots = [
            ['code'=>'CA1','day_of_week'=>2,'start_time'=>'07:00:00','end_time'=>'09:00:00'],
            ['code'=>'CA2','day_of_week'=>2,'start_time'=>'09:10:00','end_time'=>'11:10:00'],
        ];

        foreach ($slots as $s) {
            Timeslot::updateOrCreate(['code'=>$s['code']],$s);
        }
    }
}
