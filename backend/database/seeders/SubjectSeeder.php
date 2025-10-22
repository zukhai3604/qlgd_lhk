<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\Subject;

class SubjectSeeder extends Seeder
{
    public function run(): void
    {
        $itDepartment = Department::where('code', 'CNTT')->first();

        if (!$itDepartment) {
            $this->command?->warn('Department with code CNTT not found, skip SubjectSeeder.');
            return;
        }

        $subjects = [
            [
                'code' => 'CNW',
                'name' => 'Cong nghe Web',
                'credits' => 3,
                'total_sessions' => 30,
                'semester_label' => '2025-2026 HK1',
                'department_id' => $itDepartment->id,
            ],
            [
                'code' => 'CTDL',
                'name' => 'Cau truc du lieu',
                'credits' => 3,
                'total_sessions' => 30,
                'semester_label' => '2025-2026 HK1',
                'department_id' => $itDepartment->id,
            ],
            [
                'code' => 'CSDL',
                'name' => 'Co so du lieu',
                'credits' => 3,
                'total_sessions' => 30,
                'semester_label' => '2025-2026 HK1',
                'department_id' => $itDepartment->id,
            ],
        ];

        foreach ($subjects as $payload) {
            Subject::updateOrCreate(
                ['code' => $payload['code']],
                $payload
            );
        }
    }
}

