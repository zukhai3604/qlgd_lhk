<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\SessionUpdateRequest;
use App\Http\Resources\Lecturer\TeachingSessionResource;
use App\Models\Schedule;
use Illuminate\Http\Request;

class TeachingSessionController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/sessions",
     *   tags={"Lecturer"},
     *   summary="Danh sách buổi dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function index(Request $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        if (!$lecturerId) return response()->json(['message' => 'Không có quyền'], 403);

        $q = Schedule::query()
            ->with(['assignment.subject','assignment.classUnit','room','timeslot'])
            ->whereHas('assignment', fn($w) => $w->where('lecturer_id', $lecturerId));

        if ($d = $request->query('date')) {
            $q->whereDate('session_date', $d);
        }
        if ($from = $request->query('from')) {
            $q->whereDate('session_date', '>=', $from);
        }
        if ($to = $request->query('to')) {
            $q->whereDate('session_date', '<=', $to);
        }
        if ($st = $request->query('status')) {
            $q->where('status', $st);
        }

        $items = $q->orderBy('session_date')->paginate(20);
        return TeachingSessionResource::collection($items)->additional(['meta' => ['total' => $items->total()]]);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/sessions/{id}",
     *   tags={"Lecturer"},
     *   summary="Chi tiết buổi dạy",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     *   @OA\Response(response=404, description="Not Found")
     * )
     */
    public function show(Request $request, $id)
    {
        $s = Schedule::with(['assignment.subject','assignment.classUnit','room','timeslot'])->find($id);
        if (!$s) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($s->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        return response()->json(['data' => new TeachingSessionResource($s)]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/sessions/{id}",
     *   tags={"Lecturer"},
     *   summary="Cập nhật buổi dạy (note/room khi PLANNED)",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     *   @OA\Response(response=404, description="Not Found"),
     *   @OA\Response(response=422, description="Unprocessable Entity")
     * )
     */
    public function update(SessionUpdateRequest $request, $id)
    {
        $s = Schedule::find($id);
        if (!$s) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($s->assignment?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        if ($s->status !== 'PLANNED') {
            return response()->json(['message' => 'Chỉ sửa khi trạng thái PLANNED'], 422);
        }
        $s->fill($request->validated());
        $s->save();
        $s->load(['assignment.subject','assignment.classUnit','room','timeslot']);
        return response()->json(['data' => new TeachingSessionResource($s)]);
    }
}

