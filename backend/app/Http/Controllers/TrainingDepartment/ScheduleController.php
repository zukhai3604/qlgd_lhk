<?php
namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\{LeaveRequest, MakeupRequest};
use Illuminate\Http\Request;

class RequestBrowseController extends Controller
{
    // GET /api/training_department/requests?type=leave|makeup&status=&lecturer_id=&from=&to=&per_page=
    public function index(Request $req){
        $status = $req->get('status');
        $lecturerId = $req->get('lecturer_id');
        $from = $req->get('from'); $to = $req->get('to');
        $per = min((int)$req->get('per_page',15), 100);

        $leave = LeaveRequest::query()
            ->with([
                'schedule:id,session_date,timeslot_id,room_id,status,assignment_id',
                'schedule.timeslot:id,code,day_of_week,start_time,end_time',
                'schedule.room:id,code',
                'schedule.assignment.subject:id,code,name',
                'schedule.assignment.classUnit:id,code,name',
                'lecturer.user:id,name,email',
            ])
            ->when($status, fn($q)=>$q->where('status',$status))
            ->when($lecturerId, fn($q)=>$q->where('lecturer_id',$lecturerId))
            ->when($from, fn($q)=>$q->whereHas('schedule', fn($qq)=>$qq->whereDate('session_date','>=',$from)))
            ->when($to, fn($q)=>$q->whereHas('schedule', fn($qq)=>$qq->whereDate('session_date','<=',$to)));

        $makeup = MakeupRequest::query()
            ->with([
                'timeslot:id,code,day_of_week,start_time,end_time',
                'room:id,code',
                'leaveRequest.schedule.assignment.subject:id,code,name',
                'leaveRequest.schedule.assignment.classUnit:id,code,name',
                'leaveRequest.lecturer.user:id,name,email',
            ])
            ->when($status, fn($q)=>$q->where('status',$status))
            ->when($lecturerId, fn($q)=>$q->whereHas('leaveRequest', fn($qq)=>$qq->where('lecturer_id',$lecturerId)))
            ->when($from, fn($q)=>$q->whereDate('suggested_date','>=',$from))
            ->when($to, fn($q)=>$q->whereDate('suggested_date','<=',$to));

        if ($req->get('type') === 'leave')  return response()->json(['message'=>'OK','data'=>$leave->paginate($per)]);
        if ($req->get('type') === 'makeup') return response()->json(['message'=>'OK','data'=>$makeup->paginate($per)]);

        return response()->json([
            'message'=>'OK',
            'data'=>[
                'leave'  => $leave->paginate($per, ['*'], 'leave_page'),
                'makeup' => $makeup->paginate($per, ['*'], 'makeup_page'),
            ]
        ]);
    }

    // GET /api/training_department/requests/{type}/{id}
    public function show($type, $id){
        if ($type === 'leave') {
            $lr = LeaveRequest::with([
                'schedule.timeslot','schedule.room',
                'schedule.assignment.subject','schedule.assignment.classUnit',
                'lecturer.user'
            ])->findOrFail($id);
            return response()->json(['message'=>'OK','data'=>$lr]);
        }
        if ($type === 'makeup') {
            $mk = MakeupRequest::with([
                'timeslot','room',
                'leaveRequest.schedule.assignment.subject',
                'leaveRequest.schedule.assignment.classUnit',
                'leaveRequest.lecturer.user'
            ])->findOrFail($id);
            return response()->json(['message'=>'OK','data'=>$mk]);
        }
        return response()->json(['message'=>'type phải là leave hoặc makeup'], 422);
    }
}
