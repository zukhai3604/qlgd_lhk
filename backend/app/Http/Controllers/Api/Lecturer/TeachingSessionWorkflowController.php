<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\Schedule;
use Illuminate\Http\Request;

class TeachingSessionWorkflowController extends Controller
{
    /**
     * @OA\Post(
     *   path="/api/lecturer/sessions/{id}/start",
     *   tags={"Lecturer"},
     *   summary="Start session",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     *   @OA\Response(response=404, description="Not Found"),
     *   @OA\Response(response=422, description="Unprocessable Entity")
     * )
     */
    public function start(Request $request, $id)
    {
        $s = Schedule::find($id);
        if (!$s) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($s->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        if ($s->status !== 'PLANNED') {
            return response()->json(['message' => 'Chỉ start khi PLANNED'], 422);
        }
        $s->status = 'TEACHING';
        $s->save();
        return response()->json(['data' => ['id' => $s->id, 'status' => $s->status]]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/sessions/{id}/finish",
     *   tags={"Lecturer"},
     *   summary="Finish session",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     *   @OA\Response(response=404, description="Not Found"),
     *   @OA\Response(response=422, description="Unprocessable Entity")
     * )
     */
    public function finish(Request $request, $id)
    {
        $s = Schedule::find($id);
        if (!$s) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($s->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        if (!in_array($s->status, ['PLANNED','TEACHING'], true)) {
            return response()->json(['message' => 'Chỉ finish khi PLANNED/TEACHING'], 422);
        }
        $hasAttendance = AttendanceRecord::where('schedule_id', $s->id)->exists();
        if (!$hasAttendance) {
            return response()->json(['message' => 'Cần có điểm danh trước khi hoàn tất'], 422);
        }
        $s->status = 'DONE';
        $s->save();
        return response()->json(['data' => ['id' => $s->id, 'status' => $s->status]]);
    }
}

