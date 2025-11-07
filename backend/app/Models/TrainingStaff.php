<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrainingStaff extends Model
{
    protected $table = 'training_staff';

    protected $fillable = [
        'user_id',
        'gender',
        'date_of_birth',
        'position',
        'avatar_url',
    ];

    protected $casts = [
        'date_of_birth' => 'date',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

