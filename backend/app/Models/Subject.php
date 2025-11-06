<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Subject extends Model
{
    protected $fillable = ['code','name','credits','total_sessions','theory_hours','practice_hours','department_id'];

    public function department(){ return $this->belongsTo(Department::class); }
    public function assignments(){ return $this->hasMany(Assignment::class); }
}
