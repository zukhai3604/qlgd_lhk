<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaveRequest extends Model
{
    protected $fillable = ['schedule_id','lecturer_id','reason','proof_url','status','requested_at','decided_at','decided_by'];
    protected $casts = ['requested_at' => 'datetime','decided_at' => 'datetime'];

    public function schedule(){ return $this->belongsTo(Schedule::class); }
    public function lecturer(){ return $this->belongsTo(Lecturer::class); }
    public function decider(){ return $this->belongsTo(User::class,'decided_by'); }
}
