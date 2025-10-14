<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Faculty;

class FacultySeeder extends Seeder
{
    public function run(): void
    {
        Faculty::updateOrCreate(
            ['code' => 'KCNTT'],
            ['name' => 'Khoa Công nghệ Thông tin']
        );
    }
}
