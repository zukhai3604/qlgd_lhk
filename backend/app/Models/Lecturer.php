<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Lecturer extends Model
{
    protected $fillable = [
        'user_id',
        'department_id',
        'department_name',
        'faculty_name',
        'gender',
        'date_of_birth',
        'avatar_url',
    ];

    protected $casts = [
        'date_of_birth' => 'date',
    ];

    public function user(){ return $this->belongsTo(User::class); }
    public function department(){ return $this->belongsTo(Department::class); }
    public function assignments(){ return $this->hasMany(Assignment::class); }
}
