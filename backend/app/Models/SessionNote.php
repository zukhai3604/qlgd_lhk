<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SessionNote extends Model
{
    protected $fillable = ['schedule_id','topic','content','evidence_url'];

    public function schedule(){ return $this->belongsTo(Schedule::class); }
}
