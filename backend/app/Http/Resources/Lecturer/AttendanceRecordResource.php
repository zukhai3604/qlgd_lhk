<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class AttendanceRecordResource extends JsonResource
{
    public function toArray($request)
    {
        $r = $this->resource;
        return [
            'id' => $r->id,
            'schedule_id' => $r->schedule_id,
            'student' => $r->student ? [
                'id' => $r->student->id,
                'code' => $r->student->code ?? null,
                'name' => $r->student->name ?? null,
            ] : null,
            'status' => $r->status,
            'note' => $r->note,
            'marked_by' => $r->marked_by,
            'marked_at' => optional($r->marked_at)->toDateTimeString(),
        ];
    }
}

