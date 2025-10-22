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
                'name' => 'Quan tri he thong',
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
                'name' => 'Phong Dao tao',
                'email' => 'daotao@tlu.edu.vn',
                'phone' => '0900000002',
                'date_of_birth' => '1985-05-05',
                'gender' => 'Nam',
                'department' => 'Phong Dao tao',
                'faculty' => 'Phong ban',
                'role' => 'DAO_TAO',
                'avatar' => 'https://i.pravatar.cc/150?img=2',
            ],
            [
                'name' => 'Lecturer Nguyen Van An',
                'email' => 'nguyenvanan@tlu.edu.vn',
                'phone' => '0900000101',
                'date_of_birth' => '1990-03-12',
                'gender' => 'Nam',
                'department' => 'Bo mon Cong nghe phan mem',
                'faculty' => 'Khoa Cong nghe Thong tin',
                'role' => 'GIANG_VIEN',
                'avatar' => 'https://i.pravatar.cc/150?img=3',
            ],
            [
                'name' => 'Lecturer Tran Thi Binh',
                'email' => 'tranthibinh@tlu.edu.vn',
                'phone' => '0900000102',
                'date_of_birth' => '1989-08-24',
                'gender' => 'Nam',
                'department' => 'Bo mon He thong thong tin',
                'faculty' => 'Khoa Cong nghe Thong tin',
                'role' => 'GIANG_VIEN',
                'avatar' => 'https://i.pravatar.cc/150?img=4',
            ],
            [
                'name' => 'Lecturer Pham Thai Son',
                'email' => 'phamthaison@tlu.edu.vn',
                'phone' => '0900000103',
                'date_of_birth' => '1987-11-02',
                'gender' => 'Nam',
                'department' => 'Bo mon Khoa hoc may tinh',
                'faculty' => 'Khoa Cong nghe Thong tin',
                'role' => 'GIANG_VIEN',
                'avatar' => 'https://i.pravatar.cc/150?img=5',
            ],
        ];

        foreach ($users as $payload) {
            User::updateOrCreate(
                ['email' => $payload['email']],
                [
                    'name' => $payload['name'],
                    'phone' => $payload['phone'],
                    'date_of_birth' => $payload['date_of_birth'],
                    'gender' => $payload['gender'],
                    'department' => $payload['department'],
                    'faculty' => $payload['faculty'],
                    'password' => Hash::make('12345678'),
                    'role' => $payload['role'],
                    'avatar' => $payload['avatar'],
                    'is_active' => true,
                ]
            );
        }
    }
}
