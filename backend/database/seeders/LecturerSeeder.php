<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Department;
use App\Models\Lecturer;

class LecturerSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::where('email','dungkt@tlu.edu.vn')->first();
        $dept = Department::where('code','CNTT')->first();

        if ($user && $dept) {
            Lecturer::updateOrCreate(
                ['user_id' => $user->id],
                ['department_id' => $dept->id, 'degree' => 'ThS', 'phone' => '0900000003']
            );
        }
    }
}
