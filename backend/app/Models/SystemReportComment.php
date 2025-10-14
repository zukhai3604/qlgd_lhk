<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemReportComment extends Model
{
    public $timestamps = false;

    protected $fillable = ['report_id','author_user_id','body','created_at'];
    protected $casts = ['created_at' => 'datetime'];

    public function report(){ return $this->belongsTo(SystemReport::class,'report_id'); }
    public function author(){ return $this->belongsTo(User::class,'author_user_id'); }
}
