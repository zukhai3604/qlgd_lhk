<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            // === NHÓM 1
            UserSeeder::class,
            FacultySeeder::class,
            DepartmentSeeder::class,
            RoomSeeder::class,
            TimeslotSeeder::class,
            StudentSeeder::class,

            // === NHÓM 2
            LecturerSeeder::class,
            SubjectSeeder::class,
            ClassUnitSeeder::class,
            ClassStudentSeeder::class,

            // === NHÓM 3
            AssignmentSeeder::class,
            ScheduleSeeder::class,

            // === NHÓM 4
            NotificationSeeder::class,
        ]);
    }
}
