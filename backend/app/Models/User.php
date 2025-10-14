<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $fillable = ['name','email','phone','password','role','is_active'];
    protected $hidden = ['password','remember_token'];

    public function lecturer(){ return $this->hasOne(Lecturer::class); }
    public function authSessions(){ return $this->hasMany(AuthSession::class); }
    public function notificationsTo(){ return $this->hasMany(Notification::class,'to_user_id'); }
    public function notificationsFrom(){ return $this->hasMany(Notification::class,'from_user_id'); }
}
