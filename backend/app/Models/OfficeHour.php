<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class OfficeHour extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'lecturer_id','weekday','start_time','end_time','location','repeat_rule','note'
    ];

    protected $casts = [
        'weekday' => 'integer',
        'start_time' => 'datetime:H:i:s',
        'end_time' => 'datetime:H:i:s',
    ];

    public function lecturer()
    {
        return $this->belongsTo(Lecturer::class);
    }
}

