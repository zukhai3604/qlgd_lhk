<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Schedule;
use App\Models\SessionMaterial;

class MaterialController extends Controller
{
    /**
     * GET /api/lecturer/schedule/{id}/materials
     */
    public function index(Request $request, $id)
    {
        $user = $request->user();

        // Chỉ cho GV sở hữu buổi học xem
        $schedule = Schedule::with('assignment.lecturer.user')->findOrFail($id);
        abort_if(optional($schedule->assignment?->lecturer?->user)->id !== $user->id, 403);

        // ⚠️ KHÔNG dùng created_at (bảng không có). Sắp theo uploaded_at DESC rồi fallback id DESC
        $materials = SessionMaterial::where('schedule_id', $id)
            ->orderByDesc('uploaded_at')
            ->orderByDesc('id')
            ->get(['id','title','file_url','file_type','uploaded_by','uploaded_at']);

        return response()->json(['data' => $materials]);
    }

    /**
     * POST /api/lecturer/schedule/{id}/materials
     * Body ví dụ:
     * { "title": "Chương 4: Xử lý dữ liệu", "file_url": null, "file_type": null }
     */
    public function store(Request $request, $id)
    {
        $user = $request->user();

        $schedule = Schedule::with('assignment.lecturer.user')->findOrFail($id);
        abort_if(optional($schedule->assignment?->lecturer?->user)->id !== $user->id, 403);

        $data = $request->validate([
            'title'     => 'required|string|max:255',
            'file_url'  => 'nullable|url|max:2048',
            'file_type' => 'nullable|string|max:50',
        ]);

        $material = SessionMaterial::create([
            'schedule_id' => $schedule->id,
            'title'       => $data['title'],
            'file_url'    => $data['file_url'] ?? null,
            'file_type'   => $data['file_type'] ?? null,
            'uploaded_by' => $user->id,
            'uploaded_at' => now(),
        ]);

        return response()->json([
            'message' => 'Đã thêm nội dung/tài liệu.',
            'data'    => $material->only(['id','title','file_url','file_type','uploaded_by','uploaded_at']),
        ], 201);
    }

    /**
     * (Tuỳ chọn) DELETE /api/lecturer/schedule/{scheduleId}/materials/{materialId}
     */
    public function destroy(Request $request, $scheduleId, $materialId)
    {
        $user = $request->user();

        $schedule = Schedule::with('assignment.lecturer.user')->findOrFail($scheduleId);
        abort_if(optional($schedule->assignment?->lecturer?->user)->id !== $user->id, 403);

        $mat = SessionMaterial::where('schedule_id', $scheduleId)->findOrFail($materialId);
        $mat->delete();

        return response()->json(['message' => 'Đã xoá tài liệu.']);
    }
}
