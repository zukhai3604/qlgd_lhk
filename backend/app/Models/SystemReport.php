<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemReport extends Model
{
    public $timestamps = false;

    protected $fillable = ['source_type','reporter_user_id','contact_email','title','description','category','severity','status','created_at','updated_at','closed_at','closed_by'];
    protected $casts = ['created_at' => 'datetime','updated_at' => 'datetime','closed_at' => 'datetime'];

    public function reporter(){ return $this->belongsTo(User::class,'reporter_user_id'); }
    public function closer(){ return $this->belongsTo(User::class,'closed_by'); }
    public function attachments(){ return $this->hasMany(SystemReportAttachment::class,'report_id'); }
    public function comments(){ return $this->hasMany(SystemReportComment::class,'report_id'); }
}
