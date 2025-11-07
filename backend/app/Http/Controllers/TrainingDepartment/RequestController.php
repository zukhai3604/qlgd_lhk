<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\{LeaveRequest, MakeupRequest, Schedule};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class RequestController extends Controller
{
    // GET /api/training_department/requests?type=leave|makeup&status=&lecturer_id=&from=&to=&per_page=
    public function index(Request $r){
        $status=$r->status; $lecId=$r->lecturer_id; $from=$r->from; $to=$r->to; $type=$r->type;
        $per=min((int)($r->per_page??15),100);

        $leave = LeaveRequest::with([
            'schedule.timeslot:id,code,day_of_week,start_time,end_time',
            'schedule.room:id,code,name',
            'schedule.assignment.subject:id,code,name',
            'schedule.assignment.classUnit:id,code,name',
            'schedule.assignment.lecturer.user:id,name'
        ])
        ->when($status,fn($q)=>$q->where('status',$status))
        ->when($lecId,fn($q)=>$q->where('lecturer_id',$lecId))
        ->when($from,fn($q)=>$q->whereHas('schedule',fn($qq)=>$qq->whereDate('session_date','>=',$from)))
        ->when($to,fn($q)=>$q->whereHas('schedule',fn($qq)=>$qq->whereDate('session_date','<=',$to)));

        $makeup = MakeupRequest::with([
            'timeslot:id,code,day_of_week,start_time,end_time',
            'room:id,code,name',
            'leaveRequest.schedule.assignment.subject:id,code,name',
            'leaveRequest.schedule.assignment.classUnit:id,code,name',
            'leaveRequest.lecturer.user:id,name'
        ])
        ->when($status,fn($q)=>$q->where('status',$status))
        ->when($lecId,fn($q)=>$q->whereHas('leaveRequest',fn($qq)=>$qq->where('lecturer_id',$lecId)))
        ->when($from,fn($q)=>$q->whereDate('suggested_date','>=',$from))
        ->when($to,fn($q)=>$q->whereDate('suggested_date','<=',$to));

        if ($type==='leave')  return response()->json(['message'=>'OK','data'=>$leave->paginate($per)]);
        if ($type==='makeup') return response()->json(['message'=>'OK','data'=>$makeup->paginate($per)]);

        return response()->json(['message'=>'OK','data'=>[
            'leave'  => $leave->paginate($per,['*'],'leave_page'),
            'makeup' => $makeup->paginate($per,['*'],'makeup_page'),
        ]]);
    }

    // GET /api/training_department/requests/{type}/{id}
    public function show($type,$id){
        if ($type==='leave'){
            $lr=LeaveRequest::with([
                'schedule.timeslot','schedule.room',
                'schedule.assignment.subject','schedule.assignment.classUnit',
                'schedule.assignment.lecturer.user'
            ])->findOrFail($id);
            return response()->json(['message'=>'OK','data'=>$lr]);
        }
        if ($type==='makeup'){
            $mk=MakeupRequest::with([
                'timeslot','room',
                'leaveRequest.schedule.assignment.subject','leaveRequest.schedule.assignment.classUnit',
                'leaveRequest.lecturer.user'
            ])->findOrFail($id);
            return response()->json(['message'=>'OK','data'=>$mk]);
        }
        abort(404);
    }

    // POST /api/training_department/leave/{id}/approve
    public function approveLeave($id, Request $r){
        $leave = LeaveRequest::with('schedule')->findOrFail($id);
        if ($leave->status !== 'PENDING') return response()->json(['message'=>'Invalid state'], 422);

        DB::transaction(function() use ($leave,$r){
            $leave->update([
                'status'=>'APPROVED',
                'decided_at'=>now(),
                'decided_by'=>$r->user()->id,
            ]);
            // đánh dấu buổi nghỉ
            $leave->schedule->update(['status'=>'ABSENT']);
        });
        return response()->json(['message'=>'APPROVED']);
    }

    public function rejectLeave($id, Request $r){
        $leave = LeaveRequest::findOrFail($id);
        if ($leave->status !== 'PENDING') return response()->json(['message'=>'Invalid state'], 422);
        $leave->update(['status'=>'REJECTED','decided_at'=>now(),'decided_by'=>$r->user()->id]);
        return response()->json(['message'=>'REJECTED']);
    }

    // POST /api/training_department/makeup/{id}/approve
    public function approveMakeup($id, Request $r){
        $r->validate([
            'auto_create_schedule' => ['nullable','boolean']
        ]);
        $mk = MakeupRequest::with(['leaveRequest.schedule.assignment'])->findOrFail($id);
        if ($mk->status !== 'PENDING') return response()->json(['message'=>'Invalid state'], 422);

        DB::transaction(function() use ($mk,$r){
            $mk->update(['status'=>'APPROVED','decided_at'=>now(),'decided_by'=>$r->user()->id]);

            if ((int)$r->get('auto_create_schedule',1) === 1){
                $as = $mk->leaveRequest->schedule->assignment;
                // tạo buổi dạy bù chính thức
                Schedule::create([
                    'assignment_id' => $as->id,
                    'session_date'  => $mk->suggested_date,
                    'timeslot_id'   => $mk->timeslot_id,
                    'room_id'       => $mk->room_id,
                    'status'        => 'MAKEUP',
                    'makeup_of_id'  => $mk->leaveRequest->schedule_id
                ]);
            }
        });
        return response()->json(['message'=>'APPROVED']);
    }

    public function rejectMakeup($id, Request $r){
        $mk = MakeupRequest::findOrFail($id);
        if ($mk->status !== 'PENDING') return response()->json(['message'=>'Invalid state'], 422);
        $mk->update(['status'=>'REJECTED','decided_at'=>now(),'decided_by'=>$r->user()->id]);
        return response()->json(['message'=>'REJECTED']);
    }
}
