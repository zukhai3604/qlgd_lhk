<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\MaterialUploadRequest;
use App\Models\Schedule;
use App\Models\SessionMaterial;
use Illuminate\Http\Request;

class MaterialController extends Controller
{
    public function upload(MaterialUploadRequest $request, $id)
    {
        $schedule = Schedule::with('assignment.lecturer')->findOrFail($id);

        abort_if(
            !$schedule->assignment || !$schedule->assignment->lecturer
            || $schedule->assignment->lecturer->user_id !== $request->user()->id,
            403, 'Không có quyền.'
        );

        $path = $request->file('file')->store('materials', 'public');

        $mat = SessionMaterial::create([
            'schedule_id' => $schedule->id,
            'user_id'     => $request->user()->id,
            'title'       => $request->input('title'),
            'path'        => $path,
        ]);

        return response()->json([
            'data' => [
                'id'    => $mat->id,
                'title' => $mat->title,
                'url'   => asset('storage/'.$mat->path),
            ],
            'message' => 'Đã upload tài liệu.',
        ]);
    }

    public function list($id, Request $request)
    {
        $schedule = Schedule::with('assignment.lecturer')->findOrFail($id);

        abort_if(
            !$schedule->assignment || !$schedule->assignment->lecturer
            || $schedule->assignment->lecturer->user_id !== $request->user()->id,
            403, 'Không có quyền.'
        );

        $list = SessionMaterial::where('schedule_id', $schedule->id)
            ->latest()
            ->get()
            ->map(fn($m)=>[
                'id'=>$m->id,'title'=>$m->title,'url'=>asset('storage/'.$m->path),'created_at'=>$m->created_at
            ]);

        return response()->json(['data' => $list]);
    }
}
