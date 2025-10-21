<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\{Assignment, Schedule, Timeslot, Room};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ScheduleController extends Controller
{
    // GET /api/training_department/schedules/week?week_start=YYYY-MM-DD&lecturer_id=&class_unit_id=&room_id=&semester_label=&academic_year=
    public function week(Request $r){
        $start = Carbon::parse($r->get('week_start', now()->startOfWeek(Carbon::MONDAY)))->startOfDay();
        $end   = (clone $start)->endOfWeek(Carbon::SUNDAY);
        $q = $this->base($r)->whereBetween('session_date', [$start->toDateString(), $end->toDateString()]);
        return response()->json([
            'message'=>'OK',
            'range'=>['from'=>$start->toDateString(),'to'=>$end->toDateString()],
            'data'=>$q->orderBy('session_date')->orderBy('timeslot_id')->get()
        ]);
    }

    // GET /api/training_department/schedules/month?month=YYYY-MM&...
    public function month(Request $r){
        $month = $r->get('month', now()->format('Y-m'));
        $start = Carbon::parse($month.'-01')->startOfMonth();
        $end   = (clone $start)->endOfMonth();
        $q = $this->base($r)->whereBetween('session_date', [$start->toDateString(), $end->toDateString()]);
        return response()->json([
            'message'=>'OK',
            'range'=>['from'=>$start->toDateString(),'to'=>$end->toDateString()],
            'data'=>$q->orderBy('session_date')->orderBy('timeslot_id')->get()
        ]);
    }

    // GET /api/training_department/schedules/conflicts?date=YYYY-MM-DD&timeslot_id=&lecturer_id=&class_unit_id=&room_id=&per_page=
    // Trả về tất cả buổi trùng (theo GV / lớp / phòng) tại cùng date + timeslot
    public function conflicts(Request $r){
        $r->validate([
            'date' => ['required','date'],
            'timeslot_id' => ['nullable','integer','exists:timeslots,id'],
            'lecturer_id' => ['nullable','integer','exists:lecturers,id'],
            'class_unit_id' => ['nullable','integer','exists:class_units,id'],
            'room_id' => ['nullable','integer','exists:rooms,id'],
            'per_page' => ['nullable','integer','min:1','max:100']
        ]);

        $q = Schedule::with([
            'timeslot:id,code,day_of_week,start_time,end_time',
            'room:id,code,name',
            'assignment.subject:id,code,name',
            'assignment.classUnit:id,code,name',
            'assignment.lecturer.user:id,name'
        ])->whereDate('session_date', $r->date);

        if ($r->filled('timeslot_id')) $q->where('timeslot_id', $r->timeslot_id);

        // Xung đột: cùng date+timeslot và (cùng lecturer) OR (cùng class_unit) OR (cùng room)
        $q->when($r->lecturer_id, fn($qq)=>$qq->whereHas('assignment', fn($aq)=>$aq->where('lecturer_id',$r->lecturer_id)));
        $q->when($r->class_unit_id, fn($qq)=>$qq->whereHas('assignment', fn($aq)=>$aq->where('class_unit_id',$r->class_unit_id)));
        $q->when($r->room_id, fn($qq)=>$qq->where('room_id',$r->room_id));

        return response()->json([
            'message'=>'OK',
            'data'=>$q->orderBy('timeslot_id')->paginate($r->get('per_page', 20))
        ]);
    }

    // POST /api/training_department/schedules/generate
    // Body JSON:
    // {
    //   "assignment_ids":[1,2,...],     // CHỌN danh sách phân công; nếu không truyền sẽ lọc theo semester_label+academic_year
    //   "semester_label":"HK1",
    //   "academic_year":"2025-2026",
    //   "start_date":"2025-10-27",
    //   "total_sessions":15,             // nếu Assignment không có trường này
    //   "timeslot_id": 3,
    //   "room_id": 2
    // }
    public function generate(Request $r){
        $r->validate([
            'assignment_ids'  => ['nullable','array'],
            'assignment_ids.*'=> ['integer','exists:assignments,id'],
            'semester_label'  => ['nullable','string','max:50'],
            'academic_year'   => ['nullable','string','max:20'],
            'start_date'      => ['required','date'],
            'total_sessions'  => ['nullable','integer','min:1','max:60'],
            'timeslot_id'     => ['required','integer','exists:timeslots,id'],
            'room_id'         => ['nullable','integer','exists:rooms,id'],
        ]);

        $assignments = Assignment::query()
            ->when($r->assignment_ids, fn($q)=>$q->whereIn('id',$r->assignment_ids))
            ->when(!$r->assignment_ids && $r->semester_label && $r->academic_year,
                fn($q)=>$q->where('semester_label',$r->semester_label)->where('academic_year',$r->academic_year))
            ->get();

        $created=0; $skipped=[]; $start = Carbon::parse($r->start_date);
        DB::transaction(function() use ($assignments,$r,$start,&$created,&$skipped){
            foreach ($assignments as $as){
                $total = $as->total_sessions ?? ($r->total_sessions ?? 15);
                for($i=0;$i<$total;$i++){
                    $d = $start->copy()->addWeeks($i)->toDateString();

                    // Tránh trùng unique (assignment_id, session_date, timeslot_id)
                    $exists = Schedule::where([
                        'assignment_id' => $as->id,
                        'session_date'  => $d,
                        'timeslot_id'   => $r->timeslot_id
                    ])->exists();
                    if ($exists){ $skipped[] = ['assignment_id'=>$as->id,'date'=>$d,'reason'=>'exists']; continue; }

                    // Check xung đột (GV / lớp / phòng) cùng date+timeslot
                    $conflict = Schedule::whereDate('session_date',$d)->where('timeslot_id',$r->timeslot_id)
                        ->where(function($q) use ($as, $r){
                            $q->whereHas('assignment', fn($qq)=>$qq->where('lecturer_id',$as->lecturer_id))
                              ->orWhereHas('assignment', fn($qq)=>$qq->where('class_unit_id',$as->class_unit_id));
                            if ($r->room_id) $q->orWhere('room_id', $r->room_id);
                        })->exists();
                    if ($conflict){ $skipped[] = ['assignment_id'=>$as->id,'date'=>$d,'reason'=>'conflict']; continue; }

                    Schedule::create([
                        'assignment_id' => $as->id,
                        'session_date'  => $d,
                        'timeslot_id'   => $r->timeslot_id,
                        'room_id'       => $r->room_id,
                        'status'        => 'PLANNED',
                        'makeup_of_id'  => null
                    ]);
                    $created++;
                }
            }
        });

        return response()->json(['message'=>'Generated','data'=>compact('created','skipped')], 201);
    }

    // POST /api/training_department/schedules/bulk-adjust
    // Body JSON: { "schedule_ids":[...], "room_id":?, "timeslot_id":? }
    // Dùng để đổi phòng/ca cho nhiều buổi CHƯA diễn ra (tránh trùng/va chạm)
    public function bulkAdjust(Request $r){
        $r->validate([
            'schedule_ids'   => ['required','array','min:1'],
            'schedule_ids.*' => ['integer','exists:schedules,id'],
            'room_id'        => ['nullable','integer','exists:rooms,id'],
            'timeslot_id'    => ['nullable','integer','exists:timeslots,id'],
        ]);
        if (!$r->room_id && !$r->timeslot_id) {
            return response()->json(['message'=>'Require at least room_id or timeslot_id'], 422);
        }

        $affected=0; $errors=[];
        DB::transaction(function() use ($r,&$affected,&$errors){
            $schedules = Schedule::with('assignment')->whereIn('id',$r->schedule_ids)->get();
            foreach($schedules as $s){
                try{
                    $date = $s->session_date;
                    $newRoom = $r->room_id ?? $s->room_id;
                    $newSlot = $r->timeslot_id ?? $s->timeslot_id;

                    // Không cho đổi nếu đã TAUGHT / ABSENT / CANCELED
                    if (in_array($s->status, ['TAUGHT','ABSENT','CANCELED'])) {
                        throw new \RuntimeException('Session already finished or canceled');
                    }

                    // Kiểm tra xung đột sau điều chỉnh
                    $conflict = Schedule::whereDate('session_date',$date)
                        ->where('timeslot_id', $newSlot)
                        ->where('id','!=',$s->id)
                        ->where(function($q) use ($s,$newRoom){
                            $q->whereHas('assignment', fn($qq)=>$qq->where('lecturer_id',$s->assignment->lecturer_id))
                              ->orWhereHas('assignment', fn($qq)=>$qq->where('class_unit_id',$s->assignment->class_unit_id));
                            if ($newRoom) $q->orWhere('room_id',$newRoom);
                        })->exists();
                    if ($conflict) throw new \RuntimeException('Conflict detected');

                    $s->update(['room_id'=>$newRoom, 'timeslot_id'=>$newSlot]);
                    $affected++;
                }catch(\Throwable $e){
                    $errors[] = ['id'=>$s->id,'error'=>$e->getMessage()];
                }
            }
        });

        return response()->json(['message'=>'Bulk adjust done','data'=>compact('affected','errors')]);
    }

    private function base(Request $r){
        return Schedule::with([
            'timeslot:id,code,day_of_week,start_time,end_time',
            'room:id,code,name',
            'assignment.subject:id,code,name',
            'assignment.classUnit:id,code,name',
            'assignment.lecturer.user:id,name'
        ])
        ->when($r->lecturer_id, fn($q)=>$q->whereHas('assignment',fn($qq)=>$qq->where('lecturer_id',$r->lecturer_id)))
        ->when($r->class_unit_id, fn($q)=>$q->whereHas('assignment',fn($qq)=>$qq->where('class_unit_id',$r->class_unit_id)))
        ->when($r->room_id, fn($q)=>$q->where('room_id',$r->room_id))
        ->when($r->semester_label && $r->academic_year, fn($q)=>$q->whereHas('assignment', fn($qq)=>$qq
            ->where('semester_label',$r->semester_label)->where('academic_year',$r->academic_year)));
    }
}
