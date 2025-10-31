<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DemoLecturerUsersSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name' => 'ThS. Kieu Tuan Dung',
                'email' => 'dungkt@tlu.edu.vn',
                'phone' => '0900000003',
            ],
            [
                'name' => 'Lecturer Nguyen Van An',
                'email' => 'nguyenvanan@tlu.edu.vn',
                'phone' => '0900000101',
            ],
            [
                'name' => 'Lecturer Tran Thi Binh',
                'email' => 'tranthibinh@tlu.edu.vn',
                'phone' => '0900000102',
            ],
            [
                'name' => 'Lecturer Pham Thai Son',
                'email' => 'phamthaison@tlu.edu.vn',
                'phone' => '0900000103',
            ],
        ];

        foreach ($users as $u) {
            User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'name' => $u['name'],
                    'phone' => $u['phone'] ?? null,
                    'password' => Hash::make('12345678'),
                    'role' => 'GIANG_VIEN',
                    'is_active' => true,
                ]
            );
        }
    }
}
