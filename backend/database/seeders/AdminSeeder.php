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
                    'gender' => null,
                    'date_of_birth' => null,
                    'avatar_url' => null,
                ]
            );
        }
    }
}

