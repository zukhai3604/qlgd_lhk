<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // GET /api/training_department/reports/overview?semester_label=&academic_year=
    // Tổng hợp theo giảng viên: số buổi PLANNED/TAUGHT/ABSENT/MAKEUP/CANCELED
    public function semesterOverview(Request $r){
        $r->validate([
            'semester_label' => ['required','string'],
            'academic_year'  => ['required','string'],
        ]);

        $rows = DB::table('schedules as s')
            ->join('assignments as a','a.id','=','s.assignment_id')
            ->join('lecturers as l','l.id','=','a.lecturer_id')
            ->selectRaw("
                l.id as lecturer_id, l.name as lecturer_name,
                SUM(s.status='PLANNED') as planned,
                SUM(s.status='TAUGHT') as taught,
                SUM(s.status='ABSENT') as absent,
                SUM(s.status='MAKEUP') as makeup,
                SUM(s.status='CANCELED') as canceled,
                COUNT(*) as total
            ")
            ->where('a.semester_label', $r->semester_label)
            ->where('a.academic_year',  $r->academic_year)
            ->groupBy('l.id','l.name')
            ->orderBy('l.name')
            ->get();

        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    // GET /api/training_department/reports/subject-progress?semester_label=&academic_year=
    public function subjectProgress(Request $r){
        $r->validate([
            'semester_label' => ['required','string'],
            'academic_year'  => ['required','string'],
        ]);

        $rows = DB::table('schedules as s')
            ->join('assignments as a','a.id','=','s.assignment_id')
            ->join('subjects as sub','sub.id','=','a.subject_id')
            ->selectRaw("
                sub.code, sub.name,
                SUM(s.status='TAUGHT') as taught,
                SUM(s.status='PLANNED') as remaining,
                COUNT(*) as total
            ")
            ->where('a.semester_label', $r->semester_label)
            ->where('a.academic_year',  $r->academic_year)
            ->groupBy('sub.code','sub.name')
            ->orderBy('sub.code')
            ->get();

        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    // GET /api/training_department/reports/lecturer-progress?semester_label=&academic_year=
    public function lecturerProgress(Request $r){
        $r->validate([
            'semester_label' => ['required','string'],
            'academic_year'  => ['required','string'],
        ]);

        $rows = DB::table('schedules as s')
            ->join('assignments as a','a.id','=','s.assignment_id')
            ->join('lecturers as l','l.id','=','a.lecturer_id')
            ->selectRaw("
                l.id, l.name,
                SUM(s.status='TAUGHT') as taught,
                SUM(s.status='PLANNED') as remaining,
                COUNT(*) as total
            ")
            ->where('a.semester_label', $r->semester_label)
            ->where('a.academic_year',  $r->academic_year)
            ->groupBy('l.id','l.name')
            ->orderBy('l.name')
            ->get();

        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    // GET /api/training_department/reports/class-progress?semester_label=&academic_year=
    public function classProgress(Request $r){
        $r->validate([
            'semester_label' => ['required','string'],
            'academic_year'  => ['required','string'],
        ]);

        $rows = DB::table('schedules as s')
            ->join('assignments as a','a.id','=','s.assignment_id')
            ->join('class_units as c','c.id','=','a.class_unit_id')
            ->selectRaw("
                c.code, c.name,
                SUM(s.status='TAUGHT') as taught,
                SUM(s.status='PLANNED') as remaining,
                COUNT(*) as total
            ")
            ->where('a.semester_label', $r->semester_label)
            ->where('a.academic_year',  $r->academic_year)
            ->groupBy('c.code','c.name')
            ->orderBy('c.code')
            ->get();

        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    // GET /api/training_department/reports/subject-sessions?semester_label=&academic_year=&subject_code=
    public function subjectSessions(Request $r){
        $r->validate([
            'semester_label' => ['required','string'],
            'academic_year'  => ['required','string'],
            'subject_code'   => ['required','string'],
        ]);

        $rows = DB::table('schedules as s')
            ->join('assignments as a','a.id','=','s.assignment_id')
            ->join('subjects as sub','sub.id','=','a.subject_id')
            ->join('timeslots as t','t.id','=','s.timeslot_id')
            ->leftJoin('rooms as r','r.id','=','s.room_id')
            ->selectRaw("
                s.session_date, t.code as timeslot, r.code as room_code, s.status
            ")
            ->where('a.semester_label', $r->semester_label)
            ->where('a.academic_year',  $r->academic_year)
            ->where('sub.code', $r->subject_code)
            ->orderBy('s.session_date')->orderBy('t.code')
            ->get();

        return response()->json(['message'=>'OK','data'=>$rows]);
    }

    // POST /api/training_department/data/push-class-students
    // (để nguyên nếu bạn đã viết thủ tục — ở đây giữ stub an toàn)
    public function pushClassStudents(Request $r){
        // DB::statement("CALL sp_push_students_into_class(?)", [$r->batch_tag]);
        return response()->json(['message'=>'Imported students pushed into classes (stub)']);
    }
}
