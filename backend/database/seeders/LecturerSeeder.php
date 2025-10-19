<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Lecturer;
use App\Models\Faculty;
use App\Models\Department;

class LecturerSeeder extends Seeder
{
    public function run(): void
    {
        // 1) Khoa & Bộ môn (đổi tên cho đúng với seed của bạn nếu khác)
        $faculty = Faculty::firstOrCreate(['name' => 'Khoa Công nghệ Thông tin']);
        $department = Department::firstOrCreate(
            ['name' => 'Bộ môn Công nghệ thông tin', 'faculty_id' => $faculty->id]
        );

        // 2) Tìm user giảng viên
        $user = User::where('email', 'dungkt@tlu.edu.vn')->first();

        // Phòng khi UserSeeder chưa tạo user (không bắt buộc, nhưng an toàn)
        if (!$user) {
            $user = User::create([
                'name'      => 'ThS. Kiều Tuấn Dũng',
                'email'     => 'dungkt@tlu.edu.vn',
                'phone'     => '0900000003',
                'password'  => bcrypt('12345678'),
                'role'      => 'GIANG_VIEN',
                'is_active' => true,
            ]);
        }

        // 3) Tạo/cập nhật bản ghi lecturers gắn với user
        Lecturer::updateOrCreate(
            ['user_id' => $user->id],
            [
                'gender'        => 'Nam',
                'date_of_birth' => '1990-09-20',
                'department_id' => $department->id,
                'avatar_url'    => 'https://i.pravatar.cc/150?img=3',
            ]
        );
    }
}
