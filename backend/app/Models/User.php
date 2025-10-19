<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Các trường được phép gán hàng loạt.
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'role',
        'is_active',
        'date_of_birth',
        'gender',
        'department',
        'faculty',
        'avatar',
    ];

    /**
     * Ẩn khi trả về JSON (đảm bảo bảo mật).
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Kiểu dữ liệu cho các cột.
     */
    protected $casts = [
        'is_active' => 'boolean',
        'date_of_birth' => 'date',
    ];

    /**
     * Quan hệ 1-1 với bảng lecturers (nếu có bảng riêng cho chi tiết giảng viên).
     */
    public function lecturer()
    {
        return $this->hasOne(Lecturer::class);
    }

    /**
     * Quan hệ với bảng phiên đăng nhập.
     */
    public function authSessions()
    {
        return $this->hasMany(AuthSession::class);
    }

    /**
     * Thông báo gửi đến người dùng này.
     */
    public function notificationsTo()
    {
        return $this->hasMany(Notification::class, 'to_user_id');
    }

    /**
     * Thông báo do người dùng này gửi.
     */
    public function notificationsFrom()
    {
        return $this->hasMany(Notification::class, 'from_user_id');
    }

    /**
     * Lấy đường dẫn ảnh đại diện đầy đủ (URL tuyệt đối).
     */
    public function getAvatarUrlAttribute(): string
    {
        if (!$this->avatar) {
            // Avatar mặc định nếu chưa có
            return asset('images/default-avatar.png');
        }

        // Nếu avatar đã là URL (http/https) thì trả về nguyên vẹn
        if (str_starts_with($this->avatar, 'http')) {
            return $this->avatar;
        }

        // Nếu là đường dẫn trong storage
        return asset('storage/' . $this->avatar);
    }
}
