<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Semester;
use Carbon\Carbon;

class SemesterSeeder extends Seeder
{
    public function run(): void
    {
        $semesters = [
            [
                'code' => '2024-2025 HK1',
                'name' => 'Học kỳ I 2024-2025',
                'start_date' => Carbon::parse('2024-09-01'),
                'end_date' => Carbon::parse('2024-12-31'),
            ],
            [
                'code' => '2024-2025 HK2',
                'name' => 'Học kỳ II 2024-2025',
                'start_date' => Carbon::parse('2025-01-15'),
                'end_date' => Carbon::parse('2025-05-31'),
            ],
            [
                'code' => '2025-2026 HK1',
                'name' => 'Học kỳ I 2025-2026',
                'start_date' => Carbon::parse('2025-09-01'),
                'end_date' => Carbon::parse('2025-12-31'),
            ],
            [
                'code' => '2025-2026 HK2',
                'name' => 'Học kỳ II 2025-2026',
                'start_date' => Carbon::parse('2026-01-15'),
                'end_date' => Carbon::parse('2026-05-31'),
            ],
        ];

        foreach ($semesters as $semesterData) {
            Semester::updateOrCreate(
                ['code' => $semesterData['code']],
                $semesterData
            );
        }

        $this->command->info('SemesterSeeder: Đã tạo ' . count($semesters) . ' học kỳ.');
        $this->command->info('Hệ thống sẽ tự động chuyển sang học kỳ mới khi đến ngày start_date.');
    }
}

