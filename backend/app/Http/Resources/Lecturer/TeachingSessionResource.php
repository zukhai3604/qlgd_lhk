<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class TeachingSessionResource extends JsonResource
{
    public function toArray($request)
    {
        $s = $this->resource; // Schedule
        $a = $s->assignment;
        $subject = $a?->subject;
        $classUnit = $a?->classUnit;
        $room = $s->room;
        $timeslot = $s->timeslot;
        return [
            'id' => $s->id,
            'date' => $s->session_date?->format('Y-m-d'),
            'status' => $s->status,
            'note' => $s->note,
            'subject' => $subject ? [
                'id' => $subject->id,
                'code' => $subject->code,
                'name' => $subject->name,
            ] : null,
            'class_unit' => $classUnit ? [
                'id' => $classUnit->id,
                'name' => $classUnit->name,
                'capacity' => $classUnit->capacity ?? null,
            ] : null,
            'room' => $room ? [
                'id' => $room->id,
                'name' => $room->name,
            ] : null,
            'timeslot' => $timeslot ? [
                'id' => $timeslot->id,
                'code' => $timeslot->code,
                'day_of_week' => $timeslot->day_of_week,
                'start_time' => $timeslot->start_time,
                'end_time' => $timeslot->end_time,
            ] : null,
        ];
    }
}

