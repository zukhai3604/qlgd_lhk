<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\Faculty;

class DepartmentSeeder extends Seeder
{
    public function run(): void
    {
        $faculty = Faculty::firstOrCreate(
            ['code' => 'CNTT'],
            ['name' => 'Khoa Cong nghe Thong tin']
        );

        $departments = [
            ['code' => 'CNTT', 'name' => 'Bo mon Cong nghe Thong tin'],
            ['code' => 'CNPM', 'name' => 'Bo mon Cong nghe Phan mem'],
            ['code' => 'HTTT', 'name' => 'Bo mon He thong Thong tin'],
            ['code' => 'KHMT', 'name' => 'Bo mon Khoa hoc May tinh'],
        ];

        foreach ($departments as $payload) {
            Department::updateOrCreate(
                ['code' => $payload['code']],
                [
                    'name' => $payload['name'],
                    'faculty_id' => $faculty->id,
                ]
            );
        }
    }
}

