<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\ClassUnit;

class ClassUnitSeeder extends Seeder
{
    public function run(): void
    {
        $itDepartment = Department::where('code', 'CNTT')->first();

        if (!$itDepartment) {
            $this->command?->warn('Department with code CNTT not found. Skipping ClassUnitSeeder.');
            return;
        }

        $classes = [
            [
                'code' => 'CNTT1-K65',
                'name' => 'Cong nghe thong tin 1 - K65',
                'cohort' => 'K65',
                'department_id' => $itDepartment->id,
                'size' => 60,
            ],
            [
                'code' => 'CNTT2-K65',
                'name' => 'Cong nghe thong tin 2 - K65',
                'cohort' => 'K65',
                'department_id' => $itDepartment->id,
                'size' => 55,
            ],
        ];

        foreach ($classes as $payload) {
            ClassUnit::updateOrCreate(
                ['code' => $payload['code']],
                $payload
            );
        }
    }
}

