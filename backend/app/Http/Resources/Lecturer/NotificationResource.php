<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    public function toArray($request)
    {
        $n = $this->resource;
        return [
            'id' => $n->id,
            'title' => $n->title,
            'body' => $n->body,
            'type' => $n->type,
            'status' => $n->status,
            'created_at' => optional($n->created_at)->toDateTimeString(),
            'read_at' => optional($n->read_at)->toDateTimeString(),
        ];
    }
}

