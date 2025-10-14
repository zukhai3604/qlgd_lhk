<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClassUnit extends Model
{
    protected $table = 'class_units';
    protected $fillable = ['code','name','cohort','department_id','size'];

    public function department(){ return $this->belongsTo(Department::class); }

    public function classStudents(){ return $this->hasMany(ClassStudent::class, 'class_unit_id'); }

    public function students(){
        return $this->belongsToMany(Student::class,'class_students','class_unit_id','student_id')
            ->withPivot('joined_at');
    }

    public function assignments(){ return $this->hasMany(Assignment::class,'class_unit_id'); }
}
