<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\Faculty;

class DepartmentSeeder extends Seeder
{
    public function run(): void
    {
        $faculty = Faculty::where('code','KCNTT')->first();

        Department::updateOrCreate(
            ['code' => 'CNTT'],
            ['name' => 'Bộ môn Công nghệ thông tin','faculty_id' => $faculty->id]
        );
    }
}
