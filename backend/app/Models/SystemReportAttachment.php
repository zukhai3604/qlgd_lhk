<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemReportAttachment extends Model
{
    public $timestamps = false;

    protected $fillable = ['report_id','file_url','file_type','uploaded_by','uploaded_at'];
    protected $casts = ['uploaded_at' => 'datetime'];

    public function report(){ return $this->belongsTo(SystemReport::class,'report_id'); }
    public function uploader(){ return $this->belongsTo(User::class,'uploaded_by'); }
}
