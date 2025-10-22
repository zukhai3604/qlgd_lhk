<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\AttendanceStoreRequest;
use App\Http\Resources\Lecturer\AttendanceRecordResource;
use App\Models\AttendanceRecord;
use App\Models\Schedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/sessions/{id}/attendance",
     *   tags={"Lecturer"},
     *   summary="Xem điểm danh",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     *   @OA\Response(response=404, description="Not Found")
     * )
     */
    public function show(Request $request, $id)
    {
        $s = Schedule::with('assignment')->find($id);
        if (!$s) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($s->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        $records = AttendanceRecord::with('student')->where('schedule_id', $s->id)->get();
        return AttendanceRecordResource::collection($records);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/sessions/{id}/attendance",
     *   tags={"Lecturer"},
     *   summary="Tạo/cập nhật điểm danh",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     *   @OA\Response(response=404, description="Not Found"),
     *   @OA\Response(response=422, description="Unprocessable Entity")
     * )
     */
    public function store(AttendanceStoreRequest $request, $id)
    {
        $s = Schedule::with(['assignment.classUnit'])->find($id);
        if (!$s) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($s->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validated();

        \DB::transaction(function () use ($data, $s, $request) {
            foreach ($data['records'] as $rec) {
                AttendanceRecord::updateOrCreate(
                    ['schedule_id' => $s->id, 'student_id' => $rec['student_id']],
                    [
                        'status' => $rec['status'],
                        'note' => $rec['note'] ?? null,
                        'marked_by' => $request->user()->id,
                        'marked_at' => now(),
                    ]
                );
            }
        });

        $records = AttendanceRecord::with('student')->where('schedule_id', $s->id)->get();
        return AttendanceRecordResource::collection($records)->additional(['message' => 'Đã lưu điểm danh']);
    }
}

