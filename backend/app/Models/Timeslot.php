<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Timeslot extends Model
{
    protected $fillable = ['code','day_of_week','start_time','end_time'];
}
