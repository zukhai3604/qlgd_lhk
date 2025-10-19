<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\{LeaveRequest, MakeupRequest};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RequestController extends Controller
{
    // GET /api/training_department/requests?type=leave|makeup&status=&lecturer_id=&from=&to=&per_page=
    public function index(Request $r){
        $status=$r->status; $lecId=$r->lecturer_id; $from=$r->from; $to=$r->to; $type=$r->type;
        $per=min((int)($r->per_page??15),100);

        $leave = LeaveRequest::with([
            'schedule.assignment.subject','schedule.assignment.classUnit',
            'schedule.timeslot','schedule.room','lecturer.user'
        ])
        ->when($status,fn($q)=>$q->where('status',$status))
        ->when($lecId,fn($q)=>$q->where('lecturer_id',$lecId))
        ->when($from,fn($q)=>$q->whereHas('schedule',fn($qq)=>$qq->whereDate('session_date','>=',$from)))
        ->when($to,fn($q)=>$q->whereHas('schedule',fn($qq)=>$qq->whereDate('session_date','<=',$to)));

        $makeup = MakeupRequest::with([
            'timeslot','room','leaveRequest.schedule.assignment.subject',
            'leaveRequest.schedule.assignment.classUnit','leaveRequest.lecturer.user'
        ])
        ->when($status,fn($q)=>$q->where('status',$status))
        ->when($lecId,fn($q)=>$q->whereHas('leaveRequest',fn($qq)=>$qq->where('lecturer_id',$lecId)))
        ->when($from,fn($q)=>$q->whereDate('suggested_date','>=',$from))
        ->when($to,fn($q)=>$q->whereDate('suggested_date','<=',$to));

        if ($type==='leave')  return response()->json(['message'=>'OK','data'=>$leave->paginate($per)]);
        if ($type==='makeup') return response()->json(['message'=>'OK','data'=>$makeup->paginate($per)]);

        return response()->json(['message'=>'OK','data'=>[
            'leave'=>$leave->paginate($per,['*'],'leave_page'),
            'makeup'=>$makeup->paginate($per,['*'],'makeup_page'),
        ]]);
    }

    // GET /api/training_department/requests/{type}/{id}
    public function show($type,$id){
        if ($type==='leave'){
            $lr=LeaveRequest::with(['schedule.timeslot','schedule.room','schedule.assignment.subject','schedule.assignment.classUnit','lecturer.user'])->findOrFail($id);
            return response()->json(['message'=>'OK','data'=>$lr]);
        }
        if ($type==='makeup'){
            $mk=MakeupRequest::with(['timeslot','room','leaveRequest.schedule.assignment.subject','leaveRequest.schedule.assignment.classUnit','leaveRequest.lecturer.user'])->findOrFail($id);
            return response()->json(['message'=>'OK','data'=>$mk]);
        }
        return response()->json(['message'=>'type phải là leave|makeup'],422);
    }

    // POST /api/training_department/leave/{id}/approve
    public function approveLeave($id, Request $r){
        DB::statement("CALL sp_leave_approve(?, ?, ?)", [$id, $r->user()->id, (int)$r->get('mark_absent',1)]);
        return response()->json(['message'=>'APPROVED']);
    }
    public function rejectLeave($id, Request $r){
        DB::statement("CALL sp_leave_reject(?, ?)", [$id, $r->user()->id]);
        return response()->json(['message'=>'REJECTED']);
    }

    // POST /api/training_department/makeup/{id}/approve
    public function approveMakeup($id, Request $r){
        DB::statement("CALL sp_makeup_approve(?, ?, ?)", [$id, $r->user()->id, (int)$r->get('auto_create_schedule',1)]);
        return response()->json(['message'=>'APPROVED']);
    }
    public function rejectMakeup($id, Request $r){
        DB::statement("CALL sp_makeup_reject(?, ?)", [$id, $r->user()->id]);
        return response()->json(['message'=>'REJECTED']);
    }
}
