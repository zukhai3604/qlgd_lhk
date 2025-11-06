<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;
use App\Models\Subject;

class SubjectSeeder extends Seeder
{
    public function run(): void
    {
        $itDepartment = Department::where('code', 'CNTT')->first();

        if (!$itDepartment) {
            $this->command?->warn('Department with code CNTT not found, skip SubjectSeeder.');
            return;
        }

        $subjects = [
            // Lecturer Nguyen Van An
            ['code' => 'CNW', 'name' => 'Cong nghe Web', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'PWA', 'name' => 'Phat trien Web tien tien', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'FE1', 'name' => 'Lap trinh Frontend 1', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'FE2', 'name' => 'Lap trinh Frontend 2', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'MOBILE', 'name' => 'Phat trien Ung dung Di dong', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'UXUI', 'name' => 'Thiet ke UX UI', 'credits' => 2, 'total_sessions' => 24],
            ['code' => 'API', 'name' => 'Thiet ke API', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'DEVOPS', 'name' => 'Thuc hanh DevOps', 'credits' => 3, 'total_sessions' => 30],

            // Lecturer Tran Thi Binh
            ['code' => 'CTDL', 'name' => 'Cau truc du lieu', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'GTNM', 'name' => 'Giai thuat Ngu nghia', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'OSYS', 'name' => 'He dieu hanh', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'NETWORK', 'name' => 'Mang may tinh', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'OOP2', 'name' => 'Lap trinh Huong doi tuong nang cao', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'SECURE', 'name' => 'Bao mat he thong', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'AI1', 'name' => 'Tri tue nhan tao co ban', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'CLOUD', 'name' => 'Nen tang Dien toan Dam may', 'credits' => 3, 'total_sessions' => 30],

            // Lecturer Pham Thai Son
            ['code' => 'CSDL', 'name' => 'Co so du lieu', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'BIGDATA', 'name' => 'He thong Du lieu Lon', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'DWBI', 'name' => 'Kho du lieu va BI', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'SQLADV', 'name' => 'SQL Nang cao', 'credits' => 2, 'total_sessions' => 24],
            ['code' => 'NOSQL', 'name' => 'Co so du lieu NoSQL', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'DATAAN', 'name' => 'Phan tich Du lieu', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'MLDB', 'name' => 'Hoc may voi Du lieu', 'credits' => 3, 'total_sessions' => 30],
            ['code' => 'DATAENG', 'name' => 'Ky thuat Du lieu', 'credits' => 3, 'total_sessions' => 30],
        ];

        foreach ($subjects as $payload) {
            Subject::updateOrCreate(
                ['code' => $payload['code']],
                $payload + [
                    'department_id' => $itDepartment->id,
                ]
            );
        }
    }
}
