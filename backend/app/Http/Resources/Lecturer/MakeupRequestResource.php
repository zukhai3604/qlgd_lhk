<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class MakeupRequestResource extends JsonResource
{
    public function toArray($request)
    {
        $mr = $this->resource;
        $leaveRequest = $mr->leave;
        $origSchedule = $leaveRequest?->schedule;
        $lecturer = $leaveRequest?->lecturer;
        $assignment = $origSchedule?->assignment;
        
        return [
            'id' => $mr->id,
            'leave_request_id' => $mr->leave_request_id,
            
            // Thông tin giảng viên
            'lecturer' => [
                'id' => $lecturer?->id,
                'name' => $lecturer?->user?->name,
                'email' => $lecturer?->user?->email,
                'unit' => $lecturer?->department?->faculty?->name,
            ],
            
            // Thông tin lịch học gốc (bị nghỉ)
            'original_schedule' => [
                'id' => $origSchedule?->id,
                'subject' => $assignment?->subject?->name,
                'subject_code' => $assignment?->subject?->code,
                'class' => $assignment?->classUnit?->name,
                'class_code' => $assignment?->classUnit?->code,
                'date' => $origSchedule?->session_date?->format('Y-m-d'),
                'date_formatted' => $origSchedule?->session_date?->format('d/m/Y'),
                'timeslot' => $origSchedule?->timeslot?->code,
                'room' => $origSchedule?->room?->name,
                'reason' => $leaveRequest?->reason,
            ],
            
            // Thông tin lịch học đề xuất dạy bù
            'makeup_schedule' => [
                'suggested_date' => $mr->suggested_date?->format('Y-m-d'),
                'suggested_date_formatted' => $mr->suggested_date?->format('d/m/Y'),
                'timeslot_id' => $mr->timeslot_id,
                'timeslot' => $mr->timeslot?->code,
                'timeslot_label' => $mr->timeslot?->code . ' (' . 
                    $mr->timeslot?->start_time . '-' . 
                    $mr->timeslot?->end_time . ')',
                'room_id' => $mr->room_id,
                'room' => $mr->room?->name,
                'room_code' => $mr->room?->code,
            ],
            
            // Thông tin đề xuất
            'note' => $mr->note,
            'status' => $mr->status,
            'decided_by' => $mr->decided_by,
            'decided_at' => optional($mr->decided_at)->toDateTimeString(),
        ];
    }
}

