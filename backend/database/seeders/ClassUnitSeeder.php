<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\ClassUnit;

class ClassUnitSeeder extends Seeder
{
    public function run(): void
    {
        // Find the "Công nghệ thông tin" department
        $itDepartment = Department::where('code', 'CNTT')->first();

        // Safety check: If the department isn't found, stop the seeder.
        if (!$itDepartment) {
            $this->command->warn('Department with code "CNTT" not found. Skipping ClassUnitSeeder.');
            return;
        }

        $classes = [
            [
                'code' => 'CNTT1-K65',
                'name' => 'Công nghệ thông tin 1 - K65',
                'cohort' => 'K65',
                'department_id' => $itDepartment->id,
                'size' => 60
            ],
            [
                'code' => 'CNTT2-K65',
                'name' => 'Công nghệ thông tin 2 - K65',
                'cohort' => 'K65',
                'department_id' => $itDepartment->id,
                'size' => 55
            ],
            // You can easily add more classes here
        ];

        foreach ($classes as $classData) {
            ClassUnit::updateOrCreate(
                ['code' => $classData['code']], // Key to check for existence
                $classData                     // Data to create or update
            );
        }
    }
}
