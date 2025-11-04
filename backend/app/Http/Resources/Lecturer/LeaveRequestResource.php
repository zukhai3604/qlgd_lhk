<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class LeaveRequestResource extends JsonResource
{
    public function toArray($request)
    {
        $lr = $this->resource;
        $schedule = $lr->schedule;
        
        $scheduleData = null;
        if ($schedule) {
            $timeslot = $schedule->timeslot;
            $room = $schedule->room;
            $assignment = $schedule->assignment;
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
                    'semester_label' => $assignment->semester_label,
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
        ];
    }
}

