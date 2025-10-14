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
            ['name' => 'Quản trị hệ thống', 'email' => 'admin@tlu.edu.vn', 'phone' => '0900000001', 'role' => 'ADMIN'],
            ['name' => 'Phòng Đào tạo', 'email' => 'daotao@tlu.edu.vn', 'phone' => '0900000002', 'role' => 'DAO_TAO'],
            ['name' => 'ThS. Kiều Tuấn Dũng', 'email' => 'dungkt@tlu.edu.vn', 'phone' => '0900000003', 'role' => 'GIANG_VIEN'],
        ];

        foreach ($users as $u) {
            User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'name' => $u['name'],
                    'phone' => $u['phone'],
                    'password' => Hash::make('12345678'),
                    'role' => $u['role'],
                    'is_active' => true,
                ]
            );
        }
    }
}
