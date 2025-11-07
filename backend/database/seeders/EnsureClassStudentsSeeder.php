<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Student;
use App\Models\ClassStudent;
use App\Models\ClassUnit;

/**
 * Seeder để đảm bảo tất cả các lớp đều có sinh viên
 * Chạy seeder này sau khi đã có Student và ClassUnit
 */
class EnsureClassStudentsSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('Ensuring all classes have students...');
        
        $classes = ClassUnit::where('code', 'like', 'CNTT%')->orderBy('code')->get();
        $allStudents = Student::orderBy('code')->get();
        
        if ($classes->isEmpty()) {
            $this->command->warn('No classes found.');
            return;
        }
        
        if ($allStudents->isEmpty()) {
            $this->command->warn('No students found. Please run StudentSeeder first.');
            return;
        }
        
        // Kiểm tra và đảm bảo mỗi lớp có ít nhất 50 sinh viên
        foreach ($classes as $class) {
            $existingCount = ClassStudent::where('class_unit_id', $class->id)->count();
            
            if ($existingCount < 50) {
                $this->command->info("Class {$class->code} has only {$existingCount} students. Adding more...");
                
                // Lấy các sinh viên chưa có trong lớp này
                $existingStudentIds = ClassStudent::where('class_unit_id', $class->id)
                    ->pluck('student_id')
                    ->toArray();
                
                $availableStudents = $allStudents->whereNotIn('id', $existingStudentIds);
                
                // Thêm sinh viên cho đến khi đủ 50-60 sinh viên
                $targetCount = min($class->size ?? 60, 60);
                $needed = $targetCount - $existingCount;
                
                if ($needed > 0 && $availableStudents->isNotEmpty()) {
                    $toAdd = $availableStudents->shuffle()->take(min($needed, $availableStudents->count()));
                    
                    foreach ($toAdd as $student) {
                        ClassStudent::updateOrCreate(
                            ['class_unit_id' => $class->id, 'student_id' => $student->id],
                            ['joined_at' => now()->subMonths(rand(1, 6))->subDays(rand(0, 30))]
                        );
                    }
                    
                    $this->command->info("  Added {$toAdd->count()} students to {$class->code}");
                }
            } else {
                $this->command->info("Class {$class->code}: {$existingCount} students ✓");
            }
        }
        
        $this->command->info('✅ Done ensuring students in all classes');
    }
}

