<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class OfficeHourResource extends JsonResource
{
    public function toArray($request)
    {
        $o = $this->resource;
        return [
            'id' => $o->id,
            'weekday' => $o->weekday,
            'start_time' => $o->start_time,
            'end_time' => $o->end_time,
            'location' => $o->location,
            'repeat_rule' => $o->repeat_rule,
            'note' => $o->note,
        ];
    }
}

