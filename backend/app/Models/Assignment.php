<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Assignment extends Model
{
    protected $fillable = ['lecturer_id','subject_id','class_unit_id','semester_label','academic_year'];

    public function lecturer(){ return $this->belongsTo(Lecturer::class); }
    public function subject(){ return $this->belongsTo(Subject::class); }
    public function classUnit(){ return $this->belongsTo(ClassUnit::class,'class_unit_id'); }
    public function schedules(){ return $this->hasMany(Schedule::class); }
}
