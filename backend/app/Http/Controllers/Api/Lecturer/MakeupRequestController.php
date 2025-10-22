<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\MakeupRequestStoreRequest;
use App\Http\Requests\Lecturer\MakeupRequestUpdateRequest;
use App\Http\Resources\Lecturer\MakeupRequestResource;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use Illuminate\Http\Request;

class MakeupRequestController extends Controller
{
    public function index(Request $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $items = MakeupRequest::query()
            ->whereHas('leave', fn($w) => $w->where('lecturer_id', $lecId))
            ->orderByDesc('id')
            ->paginate(20);
        return MakeupRequestResource::collection($items)->additional(['meta' => ['total' => $items->total()]]);
    }

    public function store(MakeupRequestStoreRequest $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $data = $request->validated();
        $lr = LeaveRequest::find($data['leave_request_id']);
        if (!$lr) return response()->json(['message' => 'Không tìm thấy đơn nghỉ'], 404);
        if ($lr->lecturer_id !== $lecId) return response()->json(['message' => 'Forbidden'], 403);

        $mr = new MakeupRequest($data);
        $mr->status = 'PENDING';
        $mr->save();
        return response()->json(['data' => new MakeupRequestResource($mr)], 201);
    }

    public function show(Request $request, $id)
    {
        $mr = MakeupRequest::with('leave')->find($id);
        if (!$mr) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($mr->leave?->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        return response()->json(['data' => new MakeupRequestResource($mr)]);
    }

    public function update(MakeupRequestUpdateRequest $request, $id)
    {
        $mr = MakeupRequest::with('leave')->find($id);
        if (!$mr) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($mr->leave?->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        if ($mr->status !== 'PENDING') return response()->json(['message' => 'Chỉ sửa khi PENDING'], 422);
        $mr->fill($request->validated());
        $mr->save();
        return response()->json(['data' => new MakeupRequestResource($mr)]);
    }

    public function destroy(Request $request, $id)
    {
        $mr = MakeupRequest::with('leave')->find($id);
        if (!$mr) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($mr->leave?->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        if ($mr->status !== 'PENDING') return response()->json(['message' => 'Chỉ xóa khi PENDING'], 422);
        $mr->delete();
        return response()->noContent();
    }
}
