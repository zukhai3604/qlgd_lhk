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
            // Cohort K65
            ['code' => 'CNTT1-K65', 'name' => 'Cong nghe thong tin 1 - K65', 'cohort' => 'K65', 'size' => 60],
            ['code' => 'CNTT2-K65', 'name' => 'Cong nghe thong tin 2 - K65', 'cohort' => 'K65', 'size' => 58],
            ['code' => 'CNTT3-K65', 'name' => 'Cong nghe thong tin 3 - K65', 'cohort' => 'K65', 'size' => 55],
            ['code' => 'CNTT4-K65', 'name' => 'Cong nghe thong tin 4 - K65', 'cohort' => 'K65', 'size' => 54],
            ['code' => 'CNTT5-K65', 'name' => 'Cong nghe thong tin 5 - K65', 'cohort' => 'K65', 'size' => 52],
            ['code' => 'CNTT6-K65', 'name' => 'Cong nghe thong tin 6 - K65', 'cohort' => 'K65', 'size' => 50],

            // Cohort K66
            ['code' => 'CNTT1-K66', 'name' => 'Cong nghe thong tin 1 - K66', 'cohort' => 'K66', 'size' => 61],
            ['code' => 'CNTT2-K66', 'name' => 'Cong nghe thong tin 2 - K66', 'cohort' => 'K66', 'size' => 59],
            ['code' => 'CNTT3-K66', 'name' => 'Cong nghe thong tin 3 - K66', 'cohort' => 'K66', 'size' => 57],
            ['code' => 'CNTT4-K66', 'name' => 'Cong nghe thong tin 4 - K66', 'cohort' => 'K66', 'size' => 56],
            ['code' => 'CNTT5-K66', 'name' => 'Cong nghe thong tin 5 - K66', 'cohort' => 'K66', 'size' => 55],
            ['code' => 'CNTT6-K66', 'name' => 'Cong nghe thong tin 6 - K66', 'cohort' => 'K66', 'size' => 53],

            // Cohort K67
            ['code' => 'CNTT1-K67', 'name' => 'Cong nghe thong tin 1 - K67', 'cohort' => 'K67', 'size' => 62],
            ['code' => 'CNTT2-K67', 'name' => 'Cong nghe thong tin 2 - K67', 'cohort' => 'K67', 'size' => 60],
            ['code' => 'CNTT3-K67', 'name' => 'Cong nghe thong tin 3 - K67', 'cohort' => 'K67', 'size' => 58],
            ['code' => 'CNTT4-K67', 'name' => 'Cong nghe thong tin 4 - K67', 'cohort' => 'K67', 'size' => 56],
            ['code' => 'CNTT5-K67', 'name' => 'Cong nghe thong tin 5 - K67', 'cohort' => 'K67', 'size' => 54],
            ['code' => 'CNTT6-K67', 'name' => 'Cong nghe thong tin 6 - K67', 'cohort' => 'K67', 'size' => 52],

            // Cohort K68
            ['code' => 'CNTT1-K68', 'name' => 'Cong nghe thong tin 1 - K68', 'cohort' => 'K68', 'size' => 63],
            ['code' => 'CNTT2-K68', 'name' => 'Cong nghe thong tin 2 - K68', 'cohort' => 'K68', 'size' => 61],
            ['code' => 'CNTT3-K68', 'name' => 'Cong nghe thong tin 3 - K68', 'cohort' => 'K68', 'size' => 59],
            ['code' => 'CNTT4-K68', 'name' => 'Cong nghe thong tin 4 - K68', 'cohort' => 'K68', 'size' => 57],
            ['code' => 'CNTT5-K68', 'name' => 'Cong nghe thong tin 5 - K68', 'cohort' => 'K68', 'size' => 55],
            ['code' => 'CNTT6-K68', 'name' => 'Cong nghe thong tin 6 - K68', 'cohort' => 'K68', 'size' => 53],
        ];

        foreach ($classes as $payload) {
            ClassUnit::updateOrCreate(
                ['code' => $payload['code']],
                $payload + ['department_id' => $itDepartment->id]
            );
        }
    }
}
