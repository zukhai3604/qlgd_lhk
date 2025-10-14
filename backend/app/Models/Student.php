<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = ['code','full_name','email','phone','department_id'];

    public function department(){ return $this->belongsTo(Department::class); }

    public function classStudents(){ return $this->hasMany(ClassStudent::class,'student_id'); }

    public function classes(){
        return $this->belongsToMany(ClassUnit::class,'class_students','student_id','class_unit_id')
            ->withPivot('joined_at');
    }
}
