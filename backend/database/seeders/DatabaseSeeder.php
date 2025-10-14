<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            FacultySeeder::class,
            DepartmentSeeder::class,
            UserSeeder::class,
            LecturerSeeder::class,
            ClassUnitSeeder::class,
            SubjectSeeder::class,
            RoomSeeder::class,
            TimeslotSeeder::class,
            AssignmentSeeder::class,
            ScheduleSeeder::class,
            StudentSeeder::class,
            ClassStudentSeeder::class,
            NotificationSeeder::class,
        ]);
    }
}
