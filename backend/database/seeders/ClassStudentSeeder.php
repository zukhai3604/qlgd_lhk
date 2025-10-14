<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ClassUnit;
use App\Models\Student;
use App\Models\ClassStudent;

class ClassStudentSeeder extends Seeder
{
    public function run(): void
    {
        $class = ClassUnit::where('code','CNTT1-K65')->first();

        if($class){
            $students = Student::limit(10)->get();
            foreach($students as $s){
                ClassStudent::updateOrCreate(
                    ['class_unit_id'=>$class->id,'student_id'=>$s->id],
                    ['joined_at'=>now()]
                );
            }
        }
    }
}
