<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Admin;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $admins = User::where('role', 'ADMIN')->get(['id']);
        foreach ($admins as $u) {
            Admin::firstOrCreate(
                ['user_id' => $u->id],
                [
                    'gender' => 'Nam',
                    'date_of_birth' => '1990-01-01',
                    'email' => 'admin@tlu.edu.vn',
                    'phone' => '0123456789',
                    'address' => 'Trường Đại học Thủy Lợi, Hà Nội',
                    'citizen_id' => '001234567890',
                    'avatar_url' => null,
                ]
            );
        }
    }
}

