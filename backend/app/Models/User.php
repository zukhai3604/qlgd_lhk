<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Models\Admin;

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
    ];

    /**
     * Ẩn khỏi kết quả JSON.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Kiểu dữ liệu cần cast.
     */
    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Thêm các thuộc tính ảo vào JSON
     */
    protected $appends = ['role_mapped'];

    /**
     * Accessor: Map role từ database sang frontend
     */
    public function getRoleMappedAttribute(): string
    {
        $roleMap = [
            'ADMIN' => 'admin',
            'DAO_TAO' => 'training',
            'GIANG_VIEN' => 'lecturer',
        ];
        
        return $roleMap[$this->role] ?? strtolower($this->role);
    }

    /**
     * Quan hệ 1-1 với bảng lecturers.
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
     * Thông báo gửi tới người dùng này.
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

    public function trainingStaff()
    {
        return $this->hasOne(TrainingStaff::class);
    }

    public function admin()
    {
        return $this->hasOne(Admin::class);
    }

    /**
     * URL avatar đồng nhất cho toàn hệ thống.
     */
    public function getAvatarUrlAttribute(): string
    {
        $lecturer = $this->relationLoaded('lecturer')
            ? $this->getRelation('lecturer')
            : $this->lecturer()->select(['id', 'user_id', 'avatar_url'])->first();

        $avatar = $lecturer?->avatar_url;

        if (!$avatar) {
            return asset('images/default-avatar.png');
        }

        if (str_starts_with($avatar, 'http')) {
            return $avatar;
        }

        return asset('storage/' . ltrim($avatar, '/'));
    }
}
