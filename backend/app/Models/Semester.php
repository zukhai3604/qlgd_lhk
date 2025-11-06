<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Semester extends Model
{
    use HasFactory;

    protected $fillable = [
        'code','name','start_date','end_date'
    ];
    
    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];
    
    public function assignments() {
        return $this->hasMany(Assignment::class);
    }
    
    // Scope để lấy học kỳ hiện tại (tự động dựa trên date range, không cần is_active)
    public function scopeCurrent($query) {
        $today = now();
        return $query->where('start_date', '<=', $today)
            ->where('end_date', '>=', $today)
            ->orderBy('start_date', 'desc') // Nếu có nhiều học kỳ overlap, lấy học kỳ gần nhất
            ->limit(1);
    }
    
    // Scope để lấy học kỳ tiếp theo (sắp diễn ra)
    public function scopeUpcoming($query) {
        $today = now();
        return $query->where('start_date', '>', $today)
            ->orderBy('start_date', 'asc')
            ->limit(1);
    }
    
    // Scope để lấy học kỳ active (không còn dùng, giữ lại để tương thích)
    // @deprecated - Không dùng nữa vì đã chuyển sang logic tự động dựa trên date range
    public function scopeActive($query) {
        return $query;
    }
    
    // Method để tự động lấy học kỳ hiện tại hoặc gần nhất (chỉ dựa vào date range)
    public static function getCurrentOrLatest(): ?self
    {
        $today = now();
        
        // Ưu tiên: học kỳ đang diễn ra (chỉ check date range)
        $current = static::where('start_date', '<=', $today)
            ->where('end_date', '>=', $today)
            ->orderBy('start_date', 'desc')
            ->first();
            
        if ($current) {
            return $current;
        }
        
        // Fallback: học kỳ gần nhất (theo start_date)
        return static::orderBy('start_date', 'desc')->first();
    }
}

