<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\LeaveRequest;

class ApprovalController extends Controller
{
    public function approveLeave(Request $request, LeaveRequest $leave)
    {
        // chỉ là stub demo: chuyển trạng thái sang APPROVED
        $leave->update([
            'status' => 'APPROVED',
            'decided_at' => now(),
            'decided_by' => $request->user()->id,
        ]);

        return response()->json(['message'=>'Approved','data'=>$leave]);
    }
}
