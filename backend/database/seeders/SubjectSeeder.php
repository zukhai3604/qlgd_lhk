<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\Subject;

class SubjectSeeder extends Seeder
{
    public function run(): void
    {
        $dept = Department::where('code','CNTT')->first();

        Subject::updateOrCreate(
            ['code' => 'INT101'],
            [
                'name' => 'Công nghệ Web',
                'credits' => 3,
                'total_sessions' => 15,
                'theory_hours' => 30,
                'practice_hours' => 15,
                'semester_label' => 'Xuân 2025',
                'department_id' => $dept->id
            ]
        );
    }
}
