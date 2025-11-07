<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Lecturer;
use App\Models\Department;

class LecturerSeeder extends Seeder
{
    public function run(): void
    {
        // Điền sẵn thông tin hồ sơ cho GV demo theo email
        $profileMap = [
            'dungkt@tlu.edu.vn' => ['gender' => 'Nam', 'dob' => '1985-01-15', 'dept' => 'CNTT'],
            'nguyenvanan@tlu.edu.vn' => ['gender' => 'Nam', 'dob' => '1990-05-20', 'dept' => 'CNPM'],
            'tranthibinh@tlu.edu.vn' => ['gender' => 'Nữ', 'dob' => '1991-02-10', 'dept' => 'HTTT'],
            'phamthaison@tlu.edu.vn' => ['gender' => 'Nam', 'dob' => '1987-03-05', 'dept' => 'KHMT'],
        ];

        $users = User::where('role', 'GIANG_VIEN')->get(['id','email']);
        foreach ($users as $user) {
            $p = $profileMap[$user->email] ?? null;
            $dept = $p ? Department::with('faculty')->where('code', $p['dept'])->first() : null;

            Lecturer::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'gender' => $p['gender'] ?? null,
                    'date_of_birth' => $p['dob'] ?? null,
                    'department_id' => $dept?->id,
                    'department_name' => $dept?->name,
                    'faculty_name' => $dept?->faculty?->name,
                    'avatar_url' => null,
                ]
            );
        }
    }
}
