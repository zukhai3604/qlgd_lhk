<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AdminTrainingUsersSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name' => 'System Administrator',
                'email' => 'admin@qlgd.test',
                'phone' => '0900000001',
                'role'  => 'ADMIN',
            ],
            [
                'name' => 'Training Department',
                'email' => 'dao_tao@qlgd.test',
                'phone' => '0900000002',
                'role'  => 'DAO_TAO',
            ],
        ];

        foreach ($users as $u) {
            User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'name' => $u['name'],
                    'phone' => $u['phone'] ?? null,
                    'password' => Hash::make('12345678'),
                    'role' => $u['role'],
                    'is_active' => true,
                ]
            );
        }
    }
}

