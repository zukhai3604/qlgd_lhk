<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ClassUnit;
use App\Models\Student;
use App\Models\ClassStudent;
use Carbon\Carbon;

class ClassStudentSeeder extends Seeder
{
    public function run(): void
    {
        $classes = ClassUnit::where('code', 'like', 'CNTT%')->orderBy('code')->get();
        
        if ($classes->isEmpty()) {
            $this->command?->warn('No classes found. Skipping ClassStudentSeeder.');
            return;
        }

        $allStudents = Student::orderBy('code')->get();
        
        if ($allStudents->isEmpty()) {
            $this->command?->warn('No students found. Skipping ClassStudentSeeder.');
            return;
        }

        $totalAssigned = 0;
        $studentIndex = 0;
        $classIndex = 0;
        
        // Tính số sinh viên trung bình mỗi lớp
        $avgStudentsPerClass = (int)($allStudents->count() / $classes->count());
        
        // Phân bổ sinh viên vào các lớp
        // Đảm bảo mỗi lớp đều có sinh viên, phân bổ đều từ đầu đến cuối
        foreach ($classes as $class) {
            $classIndex++;
            
            // Lấy size của lớp (số lượng sinh viên tối đa)
            $classSize = $class->size ?? 60;
            
            // Tính số sinh viên cho lớp này
            // Lớp đầu tiên và giữa: dùng số trung bình
            // Lớp cuối: lấy tất cả sinh viên còn lại
            if ($classIndex == $classes->count()) {
                // Lớp cuối cùng: lấy tất cả sinh viên còn lại
                $actualSize = min($classSize - rand(0, 5), $allStudents->count() - $studentIndex);
            } else {
                // Các lớp khác: lấy số trung bình, có thể dao động một chút
                $actualSize = min($classSize - rand(0, 5), $avgStudentsPerClass + rand(-3, 3));
            }
            
            // Đảm bảo không vượt quá số sinh viên còn lại
            $actualSize = max(1, min($actualSize, $allStudents->count() - $studentIndex));
            
            // Lấy sinh viên tiếp theo cho lớp này
            $studentsForClass = $allStudents->slice($studentIndex, $actualSize);
            
            foreach ($studentsForClass as $student) {
                // Ngày tham gia: trong vòng 1-6 tháng trước
                $joinedAt = Carbon::now()->subMonths(rand(1, 6))->subDays(rand(0, 30));
                
                ClassStudent::updateOrCreate(
                    ['class_unit_id' => $class->id, 'student_id' => $student->id],
                    ['joined_at' => $joinedAt]
                );
            }
            
            $studentIndex += $actualSize;
            $totalAssigned += $actualSize;
            
            $this->command?->info("Class {$class->code}: {$actualSize} students");
            
            // Nếu đã hết sinh viên nhưng chưa xử lý hết các lớp
            if ($studentIndex >= $allStudents->count() && $classIndex < $classes->count()) {
                // Lấy các lớp còn lại
                $remainingClasses = $classes->slice($classIndex);
                
                // Nếu còn lớp chưa xử lý nhưng hết sinh viên, lấy ngẫu nhiên từ danh sách đầy đủ
                foreach ($remainingClasses as $nextClass) {
                    $remainingSize = min($nextClass->size - rand(0, 5), 50);
                    $randomStudents = $allStudents->shuffle()->take($remainingSize);
                    
                    foreach ($randomStudents as $student) {
                        $joinedAt = Carbon::now()->subMonths(rand(1, 6))->subDays(rand(0, 30));
                        ClassStudent::updateOrCreate(
                            ['class_unit_id' => $nextClass->id, 'student_id' => $student->id],
                            ['joined_at' => $joinedAt]
                        );
                    }
                    $totalAssigned += $randomStudents->count();
                    $this->command?->info("Class {$nextClass->code}: {$randomStudents->count()} students (random)");
                }
                break;
            }
        }
        
        $this->command?->info("✅ Assigned {$totalAssigned} students to " . $classes->count() . " classes");
    }
}
