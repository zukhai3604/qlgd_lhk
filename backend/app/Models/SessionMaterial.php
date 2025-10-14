<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SessionMaterial extends Model
{
    public $timestamps = false;

    protected $fillable = ['schedule_id','title','file_url','file_type','uploaded_by','uploaded_at'];
    protected $casts = ['uploaded_at' => 'datetime'];

    public function schedule(){ return $this->belongsTo(Schedule::class); }
    public function uploader(){ return $this->belongsTo(User::class,'uploaded_by'); }
}
