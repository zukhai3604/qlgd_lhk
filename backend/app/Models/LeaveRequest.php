<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaveRequest extends Model
{
    protected $fillable = [
        'schedule_id','lecturer_id','reason','status','approved_by','approved_at','note'
    ];

    protected $casts = [
        'approved_at' => 'datetime',
    ];

    // === Quan hệ chuẩn ===

    public function schedule()
    {
        return $this->belongsTo(Schedule::class);
    }

    public function lecturer()
    {
        return $this->belongsTo(Lecturer::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
