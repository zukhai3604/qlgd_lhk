<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\ClassUnit;

class ClassUnitSeeder extends Seeder
{
    public function run(): void
    {
        $dept = Department::where('code','CNTT')->first();

        ClassUnit::updateOrCreate(
            ['code' => 'CNTT1-K65'],
            [
                'name' => 'Công nghệ thông tin 1 - K65',
                'cohort' => 'K65',
                'department_id' => $dept->id,
                'size' => 60
            ]
        );
    }
}
