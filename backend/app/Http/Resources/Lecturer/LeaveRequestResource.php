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
        
        $scheduleData = null;
        if ($schedule) {
            $timeslot = $schedule->timeslot;
            $room = $schedule->room;
            $subject = $assignment?->subject;
            $classUnit = $assignment?->classUnit;
            
            $scheduleData = [
                'id' => $schedule->id,
                'session_date' => optional($schedule->session_date)->format('Y-m-d'),
                'date' => optional($schedule->session_date)->format('Y-m-d'), // Alias
                'status' => $schedule->status,
                'note' => $schedule->note,
                'start_time' => $timeslot?->start_time,
                'end_time' => $timeslot?->end_time,
                'timeslot' => $timeslot ? [
                    'id' => $timeslot->id,
                    'code' => $timeslot->code,
                    'day_of_week' => $timeslot->day_of_week,
                    'start_time' => $timeslot->start_time,
                    'end_time' => $timeslot->end_time,
                ] : null,
                'room' => $room ? [
                    'id' => $room->id,
                    'code' => $room->code,
                    'name' => $room->code ?? $room->building,
                ] : null,
                'assignment' => $assignment ? [
                    'id' => $assignment->id,
                    'semester' => $assignment->semester ? [
                        'id' => $assignment->semester->id,
                        'code' => $assignment->semester->code,
                        'name' => $assignment->semester->name,
                    ] : null,
                    'subject' => $subject ? [
                        'id' => $subject->id,
                        'code' => $subject->code,
                        'name' => $subject->name,
                    ] : null,
                    'classUnit' => $classUnit ? [
                        'id' => $classUnit->id,
                        'code' => $classUnit->code,
                        'name' => $classUnit->name,
                    ] : null,
                ] : null,
            ];
        }
        
        return [
            'id' => $lr->id,
            'schedule_id' => $lr->schedule_id,
            'lecturer_id' => $lr->lecturer_id,
            'reason' => $lr->reason,
            'status' => $lr->status,
            'approved_by' => $lr->approved_by,
            'approved_at' => optional($lr->approved_at)->toDateTimeString(),
            'note' => $lr->note,
            'created_at' => optional($lr->created_at)->toDateTimeString(),
            'schedule' => $scheduleData,
            
            // Thông tin giảng viên
            'lecturer' => [
                'id' => $lecturer?->id,
                'name' => $lecturer?->user?->name,
                'email' => $lecturer?->user?->email,
                'unit' => $lecturer?->department?->faculty?->name,
            ],
            
            // Thông tin lịch học (formatted)
            'schedule_info' => [
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
        ];
    }
}

