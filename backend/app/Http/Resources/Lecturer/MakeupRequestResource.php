<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class MakeupRequestResource extends JsonResource
{
    public function toArray($request)
    {
        $mr = $this->resource;
        return [
            'id' => $mr->id,
            'leave_request_id' => $mr->leave_request_id,
            'suggested_date' => $mr->suggested_date?->format('Y-m-d'),
            'timeslot_id' => $mr->timeslot_id,
            'room_id' => $mr->room_id,
            'note' => $mr->note,
            'status' => $mr->status,
            'decided_by' => $mr->decided_by,
            'decided_at' => optional($mr->decided_at)->toDateTimeString(),
        ];
    }
}

