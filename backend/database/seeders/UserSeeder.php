<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name' => 'Quản trị hệ thống',
                'email' => 'admin@tlu.edu.vn',
                'phone' => '0900000001',
                'date_of_birth' => '1980-01-01',
                'gender' => 'Nam',
                'department' => null,
                'faculty' => null,
                'role' => 'ADMIN',
                'avatar' => 'https://i.pravatar.cc/150?img=1',
            ],
            [
                'name' => 'Phòng Đào tạo',
                'email' => 'daotao@tlu.edu.vn',
                'phone' => '0900000002',
                'date_of_birth' => '1985-05-05',
                'gender' => 'Nữ',
                'department' => 'Quản lý đào tạo',
                'faculty' => 'Phòng ban',
                'role' => 'DAO_TAO',
                'avatar' => 'https://i.pravatar.cc/150?img=2',
            ],
            [
                'name' => 'ThS. Kiều Tuấn Dũng',
                'email' => 'dungkt@tlu.edu.vn',
                'phone' => '0900000003',
                'date_of_birth' => '1990-09-20',
                'gender' => 'Nam',
                'department' => 'Công nghệ phần mềm',
                'faculty' => 'CNTT',
                'role' => 'GIANG_VIEN',
                'avatar' => 'https://i.pravatar.cc/150?img=3',
            ],
        ];

        foreach ($users as $u) {
            User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'name' => $u['name'],
                    'phone' => $u['phone'],
                    'date_of_birth' => $u['date_of_birth'],
                    'gender' => $u['gender'],
                    'department' => $u['department'],
                    'faculty' => $u['faculty'],
                    'password' => Hash::make('12345678'),
                    'role' => $u['role'],
                    'avatar' => $u['avatar'],
                    'is_active' => true,
                ]
            );
        }
    }
}
