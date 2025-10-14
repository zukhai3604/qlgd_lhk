<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Assignment;
use App\Models\Lecturer;
use App\Models\Subject;
use App\Models\ClassUnit;

class AssignmentSeeder extends Seeder
{
    public function run(): void
    {
        $lect = Lecturer::first();
        $subj = Subject::where('code','INT101')->first();
        $cls  = ClassUnit::where('code','CNTT1-K65')->first();

        if($lect && $subj && $cls){
            Assignment::updateOrCreate([
                'lecturer_id'=>$lect->id,
                'subject_id'=>$subj->id,
                'class_unit_id'=>$cls->id
            ],[
                'semester_label'=>'Xuân 2025',
                'academic_year'=>'2024-2025'
            ]);
        }
    }
}
