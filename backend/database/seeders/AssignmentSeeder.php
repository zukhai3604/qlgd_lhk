<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Lecturer;
use App\Models\ClassUnit;
use App\Models\Subject;
use App\Models\Assignment;

class AssignmentSeeder extends Seeder
{
    public function run(): void
    {
        // Lấy user GV có sẵn (đã tạo ở UserSeeder/LecturerSeeder)
        $gvUser = User::where('email', 'gv.a@tlu.edu.vn')->first()
            ?? User::where('email', 'dungkt@Tlu.edu.vn')->first()
            ?? User::where('role', 'GIANG_VIEN')->first();

        if (!$gvUser) {
            // fallback: tạo 1 GV mẫu đúng ENUM
            $gvUser = User::firstOrCreate(
                ['email' => 'gv.a@tlu.edu.vn'],
                [
                    'name'      => 'Giảng Viên A',
                    'password'  => bcrypt('12345678'),
                    'role'      => 'GIANG_VIEN',
                    'is_active' => true,
                ]
            );
        }

        $lec = Lecturer::firstOrCreate(
            ['user_id' => $gvUser->id],
            [
                'department_id' => 1,
                'gender'        => 'Nam',
                'date_of_birth' => '1990-09-20',
            ]
        );

        $class   = ClassUnit::first();   // đã seed ở ClassUnitSeeder
        $subject = Subject::first();     // đã seed ở SubjectSeeder

        if (!$class || !$subject) return;

        // ✅ BỔ SUNG semester_label (và các trường bắt buộc khác nếu migration có)
        Assignment::updateOrCreate(
            [
                'lecturer_id'   => $lec->id,
                'class_unit_id' => $class->id,
                'subject_id'    => $subject->id,
            ],
            [
                'semester_label' => '2025-2026 HK1',  // <-- QUAN TRỌNG
                // Nếu bảng có thêm các cột NOT NULL khác, set luôn ở đây, ví dụ:
                // 'year'  => 2025,
                // 'term'  => 1,
            ]
        );
    }
}
