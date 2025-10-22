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
        $departmentMap = [
            'nguyenvanan@tlu.edu.vn' => 'CNPM',
            'tranthibinh@tlu.edu.vn' => 'HTTT',
            'phamthaison@tlu.edu.vn' => 'KHMT',
        ];

        foreach ($departmentMap as $email => $departmentCode) {
            $user = User::where('email', $email)->first();
            if (!$user) {
                continue;
            }

            $department = Department::where('code', $departmentCode)->first()
                ?? Department::first();

            if (!$department) {
                continue;
            }

            Lecturer::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'gender' => $user->gender ?? 'Nam',
                    'date_of_birth' => $user->date_of_birth ?? '1990-01-01',
                    'department_id' => $department->id,
                    'avatar_url' => $user->avatar ?? null,
                ]
            );

            $user->department = $department->name;
            $user->faculty = $department->faculty?->name;
            $user->save();
        }
    }
}

