<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class LeaveRequestResource extends JsonResource
{
    public function toArray($request)
    {
        $lr = $this->resource;
        $schedule = $lr->schedule;
        $lecturer = $lr->lecturer;
        $assignment = $schedule?->assignment;
        
        return [
            'id' => $lr->id,
            'schedule_id' => $lr->schedule_id,
            'lecturer_id' => $lr->lecturer_id,
            
            // Thông tin giảng viên
            'lecturer' => [
                'id' => $lecturer?->id,
                'name' => $lecturer?->user?->name,
                'email' => $lecturer?->user?->email,
                'unit' => $lecturer?->department?->faculty?->name,
            ],
            
            // Thông tin lịch học
            'schedule' => [
                'id' => $schedule?->id,
                'subject' => $assignment?->subject?->name,
                'subject_code' => $assignment?->subject?->code,
                'class' => $assignment?->classUnit?->name,
                'class_code' => $assignment?->classUnit?->code,
                'date' => $schedule?->session_date?->format('Y-m-d'),
                'date_formatted' => $schedule?->session_date?->format('d/m/Y'),
                'timeslot' => $schedule?->timeslot?->code,
                'timeslot_label' => $schedule?->timeslot?->code . ' (' . 
                    $schedule?->timeslot?->start_time . '-' . 
                    $schedule?->timeslot?->end_time . ')',
                'room' => $schedule?->room?->name,
                'room_code' => $schedule?->room?->code,
            ],
            
            // Thông tin đơn nghỉ
            'reason' => $lr->reason,
            'note' => $lr->note,
            'status' => $lr->status,
            'approved_by' => $lr->approved_by,
            'approved_at' => optional($lr->approved_at)->toDateTimeString(),
            'created_at' => optional($lr->created_at)->toDateTimeString(),
        ];
    }
}

