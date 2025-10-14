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

        for($i=1; $i<=10; $i++){
            Student::updateOrCreate(
                ['code' => 'SV'.str_pad($i,3,'0',STR_PAD_LEFT)],
                [
                    'full_name' => 'Sinh viên '.$i,
                    'email' => 'sv'.$i.'@student.tlu.edu.vn',
                    'phone' => '0901000'.$i,
                    'department_id' => $dept->id
                ]
            );
        }
    }
}
