<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClassStudent extends Model
{
    public $timestamps = false;

    protected $table = 'class_students';
    protected $fillable = ['class_unit_id','student_id','joined_at'];
    protected $casts = ['joined_at' => 'datetime'];

    public function classUnit(){ return $this->belongsTo(ClassUnit::class,'class_unit_id'); }
    public function student(){ return $this->belongsTo(Student::class,'student_id'); }
}
