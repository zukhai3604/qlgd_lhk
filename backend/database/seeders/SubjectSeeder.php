<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\Subject;

class SubjectSeeder extends Seeder
{
    public function run(): void
    {
        // Find the department for "Công nghệ thông tin"
        $itDepartment = Department::where('code', 'CNTT')->first();

        // If the department doesn't exist, stop the seeder to avoid errors.
        if (!$itDepartment) {
            $this->command->warn('Department with code "CNTT" not found. Skipping SubjectSeeder.');
            return;
        }

        $subjects = [
            [
                'code' => 'INT101',
                'name' => 'Công nghệ Web',
                'credits' => 3,
                'total_sessions' => 15,
                'semester_label' => 'Xuân 2025',
                'department_id' => $itDepartment->id
            ],
            [
                'code' => 'INT102',
                'name' => 'Lập trình phân tán',
                'credits' => 3,
                'total_sessions' => 15,
                'semester_label' => 'Xuân 2025',
                'department_id' => $itDepartment->id
            ],
            // You can add more subjects here
        ];

        foreach ($subjects as $subjectData) {
            Subject::updateOrCreate(
                ['code' => $subjectData['code']], // Key to check for existence
                $subjectData                     // Data to create or update
            );
        }
    }
}
