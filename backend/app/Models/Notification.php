<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    public $timestamps = false;

    protected $fillable = ['from_user_id','to_user_id','title','body','type','status','created_at','read_at'];
    protected $casts = [
        'created_at' => 'datetime',
        'read_at' => 'datetime'
    ];

    // Accessor để tương thích với code cũ dùng read_at
    public function getIsReadAttribute()
    {
        return $this->status === 'READ' || $this->read_at !== null;
    }

    public function to()
    {
        return $this->belongsTo(User::class, 'to_user_id');
    }

    public function from()
    {
        return $this->belongsTo(User::class, 'from_user_id');
    }
}
