<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuthSession extends Model
{
    public $timestamps = false;

    protected $fillable = ['user_id','login_at','logout_at','ip_address','device_info','jwt_id','revoked'];
    protected $casts = ['login_at' => 'datetime','logout_at' => 'datetime','revoked' => 'boolean'];

    public function user(){ return $this->belongsTo(User::class); }
}
