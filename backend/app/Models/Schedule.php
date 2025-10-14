<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Schedule extends Model
{
    protected $fillable = ['assignment_id','session_date','timeslot_id','room_id','status','makeup_of_id'];
    protected $casts = ['session_date' => 'date'];

    public function assignment(){ return $this->belongsTo(Assignment::class); }
    public function timeslot(){ return $this->belongsTo(Timeslot::class); }
    public function room(){ return $this->belongsTo(Room::class); }
    public function makeupOf(){ return $this->belongsTo(Schedule::class,'makeup_of_id'); }
    public function notes(){ return $this->hasMany(SessionNote::class,'schedule_id'); }
    public function materials(){ return $this->hasMany(SessionMaterial::class,'schedule_id'); }
    public function attendanceRecords(){ return $this->hasMany(AttendanceRecord::class,'schedule_id'); }
}
