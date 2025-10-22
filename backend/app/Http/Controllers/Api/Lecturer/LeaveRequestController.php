<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\LeaveRequestStoreRequest;
use App\Http\Requests\Lecturer\LeaveRequestUpdateRequest;
use App\Http\Resources\Lecturer\LeaveRequestResource;
use App\Models\LeaveRequest;
use App\Models\Schedule;
use Illuminate\Http\Request;

class LeaveRequestController extends Controller
{
    public function index(Request $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $q = LeaveRequest::query()->where('lecturer_id', $lecId);
        if ($st = $request->query('status')) $q->where('status', $st);
        $items = $q->orderByDesc('id')->paginate(20);
        return LeaveRequestResource::collection($items)->additional(['meta' => ['total' => $items->total()]]);
    }

    public function store(LeaveRequestStoreRequest $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $data = $request->validated();
        $schedule = Schedule::with('assignment')->find($data['schedule_id']);
        if (!$schedule) return response()->json(['message' => 'Không tìm thấy lịch dạy'], 404);
        if ($schedule->assignment?->lecturer_id !== $lecId) return response()->json(['message' => 'Forbidden'], 403);

        $lr = new LeaveRequest();
        $lr->schedule_id = $schedule->id;
        $lr->lecturer_id = $lecId;
        $lr->reason = $data['reason'];
        $lr->status = 'PENDING';
        $lr->save();
        return response()->json(['data' => new LeaveRequestResource($lr)], 201);
    }

    public function show(Request $request, $id)
    {
        $lr = LeaveRequest::find($id);
        if (!$lr) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($lr->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        return response()->json(['data' => new LeaveRequestResource($lr)]);
    }

    public function update(LeaveRequestUpdateRequest $request, $id)
    {
        $lr = LeaveRequest::find($id);
        if (!$lr) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($lr->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        if ($lr->status !== 'PENDING') return response()->json(['message' => 'Chỉ sửa khi PENDING'], 422);

        $lr->fill($request->validated());
        $lr->save();
        return response()->json(['data' => new LeaveRequestResource($lr)]);
    }

    public function destroy(Request $request, $id)
    {
        $lr = LeaveRequest::find($id);
        if (!$lr) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($lr->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        if ($lr->status !== 'PENDING') return response()->json(['message' => 'Chỉ xóa khi PENDING'], 422);
        $lr->delete();
        return response()->noContent();
    }
}

