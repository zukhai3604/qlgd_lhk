<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Assignment;
use App\Models\ClassUnit;
use App\Models\Lecturer;
use App\Models\Subject;

class AssignmentSeeder extends Seeder
{
    public function run(): void
    {
        $targets = [
            [
                'subject_code' => 'CNW',
                'lecturer_email' => 'nguyenvanan@tlu.edu.vn',
                'class_code' => 'CNTT1-K65',
            ],
            [
                'subject_code' => 'CTDL',
                'lecturer_email' => 'tranthibinh@tlu.edu.vn',
                'class_code' => 'CNTT2-K65',
            ],
            [
                'subject_code' => 'CSDL',
                'lecturer_email' => 'phamthaison@tlu.edu.vn',
                'class_code' => 'CNTT1-K65',
            ],
        ];

        foreach ($targets as $item) {
            $subject = Subject::where('code', $item['subject_code'])->first();
            $classUnit = ClassUnit::where('code', $item['class_code'])->first();
            $lecturer = Lecturer::whereHas('user', function ($q) use ($item) {
                $q->where('email', $item['lecturer_email']);
            })->first();

            if (!$subject || !$classUnit || !$lecturer) {
                $this->command?->warn(sprintf(
                    'Skip assignment %s because related records missing.',
                    $item['subject_code']
                ));
                continue;
            }

            Assignment::updateOrCreate(
                [
                    'subject_id' => $subject->id,
                    'class_unit_id' => $classUnit->id,
                    'lecturer_id' => $lecturer->id,
                ],
                [
                    'semester_label' => '2025-2026 HK1',
                ]
            );
        }
    }
}

