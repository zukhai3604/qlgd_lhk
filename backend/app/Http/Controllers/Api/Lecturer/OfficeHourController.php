<?php

namespace App\Http\Controllers\Api\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\OfficeHourStoreRequest;
use App\Http\Requests\Lecturer\OfficeHourUpdateRequest;
use App\Http\Resources\Lecturer\OfficeHourResource;
use App\Models\OfficeHour;
use Illuminate\Http\Request;

class OfficeHourController extends Controller
{
    public function index(Request $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $items = OfficeHour::where('lecturer_id', $lecId)->orderBy('weekday')->get();
        return OfficeHourResource::collection($items);
    }

    public function store(OfficeHourStoreRequest $request)
    {
        $lecId = optional($request->user()->lecturer)->id;
        $o = new OfficeHour($request->validated());
        $o->lecturer_id = $lecId;
        $o->save();
        return response()->json(['data' => new OfficeHourResource($o)], 201);
    }

    public function show(Request $request, $id)
    {
        $o = OfficeHour::find($id);
        if (!$o) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($o->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        return response()->json(['data' => new OfficeHourResource($o)]);
    }

    public function update(OfficeHourUpdateRequest $request, $id)
    {
        $o = OfficeHour::find($id);
        if (!$o) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($o->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        $o->fill($request->validated());
        $o->save();
        return response()->json(['data' => new OfficeHourResource($o)]);
    }

    public function destroy(Request $request, $id)
    {
        $o = OfficeHour::find($id);
        if (!$o) return response()->json(['message' => 'Không tìm thấy'], 404);
        if ($o->lecturer_id !== optional($request->user()->lecturer)->id) return response()->json(['message' => 'Forbidden'], 403);
        $o->delete();
        return response()->noContent();
    }
}

