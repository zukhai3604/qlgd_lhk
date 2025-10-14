<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MakeupRequest extends Model
{
    protected $fillable = ['leave_request_id','suggested_date','timeslot_id','room_id','note','status','decided_at','decided_by'];
    protected $casts = ['suggested_date' => 'date','decided_at' => 'datetime'];

    public function leave(){ return $this->belongsTo(LeaveRequest::class,'leave_request_id'); }
    public function timeslot(){ return $this->belongsTo(Timeslot::class); }
    public function room(){ return $this->belongsTo(Room::class); }
    public function decider(){ return $this->belongsTo(User::class,'decided_by'); }
}
