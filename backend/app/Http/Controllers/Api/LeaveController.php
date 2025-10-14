<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use App\Models\Lecturer;
use App\Models\Schedule;
use App\Models\LeaveRequest;

class LeaveController extends Controller
{
    /**
     * POST /api/lecturer/leaves
     * Giảng viên tạo đơn xin nghỉ cho 1 schedule thuộc mình.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        // Lấy lecturer theo user hiện tại
        $lecturer = Lecturer::where('user_id', $user->id)->first();
        if (!$lecturer) {
            return response()->json(['message' => 'Không tìm thấy thông tin giảng viên.'], 404);
        }

        // Validate input
        $data = $request->validate([
            'schedule_id' => ['required', 'integer'],
            'reason'      => ['required', 'string', 'min:5'],
            'proof_url'   => ['nullable', 'string', 'max:500'],
        ]);

        // Kiểm tra schedule có thuộc giảng viên này không
        $schedule = Schedule::query()
            ->where('id', $data['schedule_id'])
            ->whereHas('assignment', function ($q) use ($lecturer) {
                $q->where('lecturer_id', $lecturer->id);
            })
            ->first();

        if (!$schedule) {
            return response()->json(['message' => 'Buổi học không thuộc quyền của giảng viên.'], 403);
        }

        // Tránh tạo trùng (unique: schedule_id + lecturer_id)
        $exists = LeaveRequest::where('schedule_id', $schedule->id)
            ->where('lecturer_id', $lecturer->id)
            ->exists();
        if ($exists) {
            return response()->json(['message' => 'Bạn đã gửi đơn cho buổi này rồi.'], 409);
        }

        // Tạo đơn
        $leave = LeaveRequest::create([
            'schedule_id'  => $schedule->id,
            'lecturer_id'  => $lecturer->id,
            'reason'       => $data['reason'],
            'proof_url'    => $data['proof_url'] ?? null,
            'status'       => 'PENDING',
            'requested_at' => now(),
        ]);

        return response()->json([
            'message' => 'Đã tạo đơn xin nghỉ.',
            'data'    => $leave,
        ], 201);
    }

    /**
     * GET /api/lecturer/leaves/my
     * Danh sách đơn nghỉ của giảng viên đang đăng nhập.
     */
    public function my(Request $request)
    {
        $user = $request->user();

        $lecturer = Lecturer::where('user_id', $user->id)->first();
        if (!$lecturer) {
            return response()->json(['message' => 'Không tìm thấy thông tin giảng viên.'], 404);
        }

        $leaves = LeaveRequest::with([
                'schedule:id,session_date,timeslot_id,room_id,status,assignment_id',
                'schedule.timeslot:id,code,day_of_week,start_time,end_time',
                'schedule.room:id,code',
                'schedule.assignment.subject:id,code,name',
                'schedule.assignment.classUnit:id,code,name',
            ])
            ->where('lecturer_id', $lecturer->id)
            ->orderByDesc('requested_at')
            ->get();

        return response()->json(['data' => $leaves]);
    }
}
