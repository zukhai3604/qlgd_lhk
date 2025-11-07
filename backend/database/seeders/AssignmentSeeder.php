<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Assignment;
use App\Models\ClassUnit;
use App\Models\Lecturer;
use App\Models\Subject;
use App\Models\Semester;

class AssignmentSeeder extends Seeder
{
    public function run(): void
    {
        $targets = [
            // Nguyen Van An
            ['subject_code' => 'CNW', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT1-K65'],
            ['subject_code' => 'PWA', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT2-K65'],
            ['subject_code' => 'FE1', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT3-K65'],
            ['subject_code' => 'FE2', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT4-K65'],
            ['subject_code' => 'MOBILE', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT5-K65'],
            ['subject_code' => 'UXUI', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT6-K65'],
            ['subject_code' => 'API', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT1-K66'],
            ['subject_code' => 'DEVOPS', 'lecturer_email' => 'nguyenvanan@tlu.edu.vn', 'class_code' => 'CNTT2-K66'],

            // Tran Thi Binh
            ['subject_code' => 'CTDL', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT3-K66'],
            ['subject_code' => 'GTNM', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT4-K66'],
            ['subject_code' => 'OSYS', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT5-K66'],
            ['subject_code' => 'NETWORK', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT6-K66'],
            ['subject_code' => 'OOP2', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT1-K67'],
            ['subject_code' => 'SECURE', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT2-K67'],
            ['subject_code' => 'AI1', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT3-K67'],
            ['subject_code' => 'CLOUD', 'lecturer_email' => 'tranthibinh@tlu.edu.vn', 'class_code' => 'CNTT4-K67'],

            // Pham Thai Son
            ['subject_code' => 'CSDL', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT5-K67'],
            ['subject_code' => 'BIGDATA', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT6-K67'],
            ['subject_code' => 'DWBI', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT1-K68'],
            ['subject_code' => 'SQLADV', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT2-K68'],
            ['subject_code' => 'NOSQL', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT3-K68'],
            ['subject_code' => 'DATAAN', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT4-K68'],
            ['subject_code' => 'MLDB', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT5-K68'],
            ['subject_code' => 'DATAENG', 'lecturer_email' => 'phamthaison@tlu.edu.vn', 'class_code' => 'CNTT6-K68'],
        ];

        // Lấy semester từ seeder (phải chạy SemesterSeeder trước)
        $semester = Semester::where('code', '2025-2026 HK1')->first();
        
        if (!$semester) {
            $this->command->warn('Semester "2025-2026 HK1" chưa được tạo. Vui lòng chạy SemesterSeeder trước.');
            return;
        }

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
                    'semester_id' => $semester->id,
                    // KHÔNG có semester_label
                ]
            );
        }
    }
}

