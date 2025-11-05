<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Student;
use App\Models\Department;

class StudentSeeder extends Seeder
{
    public function run(): void
    {
        $dept = Department::where('code','CNTT')->first();
        
        if (!$dept) {
            $this->command?->warn('Department CNTT not found. Skipping StudentSeeder.');
            return;
        }

        // Danh sách họ Việt Nam phổ biến
        $lastNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', 'Võ', 'Đặng', 'Bùi', 'Đỗ', 'Hồ', 'Ngô', 'Dương', 'Lý'];
        
        // Danh sách tên đệm phổ biến
        $middleNames = ['Văn', 'Thị', 'Đức', 'Thanh', 'Minh', 'Hoàng', 'Quang', 'Thành', 'Xuân', 'Hữu', 'Bảo', 'Công', 'Đức', 'Ngọc', 'Hải', 'Tuấn'];
        
        // Danh sách tên phổ biến
        $firstNames = [
            'An', 'Anh', 'Bảo', 'Bình', 'Chi', 'Dũng', 'Duy', 'Đạt', 'Đức', 'Giang', 'Hà', 'Hải', 'Hạnh', 'Hân', 'Hiếu', 'Hoa', 'Hoàng', 'Hùng', 'Hương', 'Huy',
            'Khánh', 'Lan', 'Linh', 'Long', 'Mai', 'Minh', 'Nam', 'Nga', 'Ngọc', 'Nhung', 'Phong', 'Phúc', 'Phương', 'Quân', 'Quang', 'Quyên', 'Sơn', 'Thanh', 'Thảo', 'Thắng',
            'Thành', 'Thiện', 'Thu', 'Thúy', 'Thư', 'Tiến', 'Toàn', 'Trang', 'Trinh', 'Trung', 'Tuấn', 'Tùng', 'Tuyết', 'Uyên', 'Vân', 'Việt', 'Vy', 'Yến'
        ];

        $createdCount = 0;
        $updatedCount = 0;
        $batchSize = 100; // Insert theo batch để tăng tốc
        
        $this->command->info("Starting to create/update 1500 students...");
        
        // Tạo 1500 sinh viên (đủ cho 24 lớp, mỗi lớp khoảng 50-60 sinh viên)
        // Với 24 lớp x 60 sinh viên = 1440, tạo thêm một chút để đảm bảo đủ
        for ($i = 1; $i <= 1500; $i++) {
            $lastName = $lastNames[array_rand($lastNames)];
            $middleName = $middleNames[array_rand($middleNames)];
            $firstName = $firstNames[array_rand($firstNames)];
            
            // Tạo tên đầy đủ
            $fullName = "$lastName $middleName $firstName";
            
            // Tạo mã sinh viên: SV + số thứ tự 3 chữ số
            $code = 'SV' . str_pad($i, 3, '0', STR_PAD_LEFT);
            
            // Tạo email
            $email = 'sv' . $i . '@student.tlu.edu.vn';
            
            // Tạo số điện thoại: 090xxxxxxx hoặc 091xxxxxxx
            $phonePrefix = (rand(0, 1) == 0) ? '090' : '091';
            $phone = $phonePrefix . str_pad(rand(1000000, 9999999), 7, '0', STR_PAD_LEFT);
            
            // Dùng updateOrCreate để đảm bảo tạo hoặc update
            $student = Student::updateOrCreate(
                ['code' => $code],
                [
                    'full_name' => $fullName,
                    'email' => $email,
                    'phone' => $phone,
                    'department_id' => $dept->id
                ]
            );
            
            // Kiểm tra xem là create hay update
            if ($student->wasRecentlyCreated) {
                $createdCount++;
            } else {
                $updatedCount++;
            }
            
            // Hiển thị progress mỗi 100 sinh viên
            if ($i % $batchSize == 0) {
                $this->command->info("Processed {$i}/1500 students...");
            }
        }
        
        $totalStudents = Student::count();
        $this->command->info("✅ Created: {$createdCount} students");
        $this->command->info("✅ Updated: {$updatedCount} students");
        $this->command->info("✅ Total students in database: {$totalStudents}");
        
        if ($totalStudents < 1500) {
            $this->command->warn("⚠️  Warning: Expected 1500 students but found {$totalStudents}. Please check for errors.");
        }
    }
}
