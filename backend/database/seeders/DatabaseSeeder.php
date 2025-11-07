<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            AdminTrainingUsersSeeder::class,
            AdminSeeder::class,
            TrainingStaffSeeder::class,
            DemoLecturerUsersSeeder::class,
            FacultySeeder::class,
            DepartmentSeeder::class,
            RoomSeeder::class,
            TimeslotSeeder::class,
            StudentSeeder::class,

            LecturerSeeder::class,
            SubjectSeeder::class,
            ClassUnitSeeder::class,
            ClassStudentSeeder::class,

            SemesterSeeder::class, // Phải chạy trước AssignmentSeeder
            AssignmentSeeder::class,
            ScheduleSeeder::class,

            NotificationSeeder::class,
            
            // Seeder dữ liệu dày đặc để test
            ComprehensiveTestDataSeeder::class,
            
            // Seeder điểm danh (sau khi có schedules)
            AttendanceRecordSeeder::class,
            AuditLogSeeder::class,
        ]);
    }
}
