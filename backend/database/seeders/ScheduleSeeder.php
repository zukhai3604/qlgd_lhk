<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Schedule;

class ScheduleSeeder extends Seeder
{
    public function run(): void
    {
        // Map trạng thái cũ -> mới đúng với ENUM trong migration
        $map = [
            'PLANNED' => 'PLANNED',
            'TAUGHT'  => 'DONE',            // cũ -> mới
            'ABSENT'  => 'CANCELED',        // cũ -> mới
            'MAKEUP'  => 'MAKEUP_PLANNED',  // cũ -> mới
            'TEACHING'=> 'TEACHING',        // nếu có dữ liệu cũ dùng TEACHING
            'DONE'    => 'DONE',
            'CANCELED'=> 'CANCELED',
            'MAKEUP_PLANNED' => 'MAKEUP_PLANNED',
            'MAKEUP_DONE'    => 'MAKEUP_DONE',
        ];

        foreach ($this->data() as $row) {
            $legacy = strtoupper($row['status'] ?? 'PLANNED');
            $mappedStatus = $map[$legacy] ?? 'PLANNED';

            Schedule::updateOrCreate(
                [
                    'assignment_id' => $row['assignment_id'],
                    'session_date'  => $row['session_date'],   // 'YYYY-MM-DD'
                    'timeslot_id'   => $row['timeslot_id'],
                ],
                [
                    'room_id'       => $row['room_id'] ?? null,
                    'status'        => $mappedStatus,
                    'note'          => $row['note'] ?? null,
                    'makeup_of_id'  => $row['makeup_of_id'] ?? null,
                ]
            );
        }
    }

    /**
     * DỮ LIỆU MẪU: bạn có thể giữ nguyên data cũ (TAUGHT/ABSENT/MAKEUP),
     * mapping ở trên sẽ tự chuyển về giá trị ENUM hợp lệ.
     */
    private function data(): array
    {
        return [
            // ví dụ: tuần này + tuần sau để test xin nghỉ
            ['assignment_id'=>1, 'session_date'=>now()->toDateString(),                 'timeslot_id'=>3, 'room_id'=>1, 'status'=>'PLANNED'],
            ['assignment_id'=>1, 'session_date'=>now()->addDays(1)->toDateString(),     'timeslot_id'=>4, 'room_id'=>1, 'status'=>'TAUGHT'],  // -> DONE
            ['assignment_id'=>1, 'session_date'=>now()->addDays(3)->toDateString(),     'timeslot_id'=>5, 'room_id'=>2, 'status'=>'ABSENT'],  // -> CANCELED
            ['assignment_id'=>1, 'session_date'=>now()->addDays(5)->toDateString(),     'timeslot_id'=>6, 'room_id'=>2, 'status'=>'MAKEUP'],  // -> MAKEUP_PLANNED
            ['assignment_id'=>1, 'session_date'=>now()->addDays(7)->toDateString(),     'timeslot_id'=>3, 'room_id'=>3, 'status'=>'PLANNED'],
        ];
    }
}
