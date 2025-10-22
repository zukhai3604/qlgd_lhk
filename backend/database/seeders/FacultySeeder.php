<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Faculty;

class FacultySeeder extends Seeder
{
    public function run(): void
    {
        Faculty::updateOrCreate(
            ['code' => 'CNTT'],
            ['name' => 'Khoa Cong nghe Thong tin']
        );
    }
}

