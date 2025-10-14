<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Department extends Model
{
    protected $fillable = ['code','name','faculty_id'];

    public function faculty(){ return $this->belongsTo(Faculty::class); }
    public function lecturers(){ return $this->hasMany(Lecturer::class); }
    public function classes(){ return $this->hasMany(ClassUnit::class,'department_id'); }
    public function subjects(){ return $this->hasMany(Subject::class); }
}
