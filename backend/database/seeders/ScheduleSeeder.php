<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Schedule;
use App\Models\Assignment;
use App\Models\Timeslot;
use App\Models\Room;

class ScheduleSeeder extends Seeder
{
    public function run(): void
    {
        $asg = Assignment::first();
        $room = Room::where('code','B5-207')->first();

        $slot1 = Timeslot::where('code','CA1')->first();
        $slot2 = Timeslot::where('code','CA2')->first();

        if($asg && $room && $slot1 && $slot2){
            Schedule::updateOrCreate([
                'assignment_id'=>$asg->id,
                'session_date'=>'2025-09-19',
                'timeslot_id'=>$slot1->id
            ],[
                'room_id'=>$room->id,
                'status'=>'TAUGHT'
            ]);

            Schedule::updateOrCreate([
                'assignment_id'=>$asg->id,
                'session_date'=>'2025-09-26',
                'timeslot_id'=>$slot2->id
            ],[
                'room_id'=>$room->id,
                'status'=>'PLANNED'
            ]);
        }
    }
}
