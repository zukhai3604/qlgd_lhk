<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Room extends Model
{
    protected $fillable = ['code','building','capacity','room_type'];

    /**
     * Accessor để lấy name từ code hoặc building
     * Giúp tương thích với code đang dùng $room->name
     */
    public function getNameAttribute()
    {
        return $this->code ?? $this->building ?? '';
    }
}
