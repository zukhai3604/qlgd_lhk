<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class LeaveController extends Controller
{
    // tạo đơn xin nghỉ
    public function store(Request $request)
    {
        $data = $request->validate([
            'schedule_id' => 'required|integer|exists:schedules,id',
            'reason'      => 'required|string|max:255',
        ]);

        // TODO: lưu leave request thực tế
        return response()->json([
            'message' => 'Đã tạo đơn xin nghỉ (demo)',
            'data' => $data,
        ], 201);
    }

    // danh sách đơn nghỉ của giảng viên
    public function my(Request $request)
    {
        // TODO: trả về danh sách thực tế
        return response()->json([
            'data' => [],
        ]);
    }
}
