<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class LeaveRequestResource extends JsonResource
{
    public function toArray($request)
    {
        $lr = $this->resource;
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
        ];
    }
}

