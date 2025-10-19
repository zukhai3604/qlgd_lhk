<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // GET /api/training_department/reports/overview?semester_label=&academic_year=
    public function semesterOverview(Request $r){
        $rows = DB::select("CALL sp_report_semester_overview(?, ?)", [$r->semester_label, $r->academic_year]);
        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    public function subjectProgress(Request $r){
        $rows = DB::select("CALL sp_report_subject_progress(?, ?, ?)", [$r->semester_label, $r->academic_year, $r->department_id]);
        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    public function lecturerProgress(Request $r){
        $rows = DB::select("CALL sp_report_lecturer_progress(?, ?, ?)", [$r->semester_label, $r->academic_year, $r->lecturer_id]);
        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    public function classProgress(Request $r){
        $rows = DB::select("CALL sp_report_class_progress(?, ?, ?)", [$r->semester_label, $r->academic_year, $r->class_id]);
        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    public function subjectSessions(Request $r){
        $rows = DB::select("CALL sp_report_subject_session_detail(?, ?, ?)", [$r->semester_label, $r->academic_year, $r->subject_code]);
        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    // POST /api/training_department/data/push-class-students
    public function pushClassStudents(Request $r){
        DB::statement("CALL sp_push_students_into_class(?)", [$r->batch_tag]);
        return response()->json(['message'=>'Imported students pushed into classes']);
    }
}
