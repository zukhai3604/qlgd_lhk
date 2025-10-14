<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceRecord extends Model
{
    public $timestamps = false;

    protected $fillable = ['schedule_id','student_id','status','note','marked_by','marked_at'];
    protected $casts = ['marked_at' => 'datetime'];

    public function schedule(){ return $this->belongsTo(Schedule::class); }
    public function student(){ return $this->belongsTo(Student::class); }
    public function marker(){ return $this->belongsTo(User::class,'marked_by'); }
}
