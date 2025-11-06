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
     * FormData với:
     * - title: "Chương 4: Xử lý dữ liệu" (required)
     * - file: File (optional, nếu có sẽ upload)
     * - file_url: URL string (optional, fallback nếu frontend gửi URL trực tiếp)
     * - file_type: string (optional)
     */
    public function store(Request $request, $id)
    {
        $user = $request->user();

        $schedule = Schedule::with('assignment.lecturer.user')->findOrFail($id);
        abort_if(optional($schedule->assignment?->lecturer?->user)->id !== $user->id, 403);

        $data = $request->validate([
            'title'     => 'required|string|max:200',
            'file'      => 'nullable|file|max:10240', // Max 10MB
            'file_url'  => 'nullable|url|max:500', // Fallback nếu frontend gửi URL trực tiếp
            'file_type' => 'nullable|string|max:50',
        ]);

        $fileUrl = null;
        $fileType = $data['file_type'] ?? null;
        
        // Xử lý upload file nếu có
        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $fileType = $fileType ?? $file->getClientMimeType();
            
            // Lưu file vào storage/public/session-materials
            $path = $file->store('session-materials', 'public');
            $fileUrl = asset('storage/' . $path);
        } elseif ($request->filled('file_url')) {
            $fileUrl = $data['file_url'];
        }

        // Chuẩn bị data để insert
        $materialData = [
            'schedule_id' => $schedule->id,
            'title'       => $data['title'],
            'uploaded_by' => $user->id,
            'uploaded_at' => now(),
        ];
        
        // Chỉ thêm file_url và file_type nếu có giá trị
        // (Tránh lỗi khi migration chưa chạy và file_url vẫn là NOT NULL)
        if ($fileUrl !== null && $fileUrl !== '') {
            $materialData['file_url'] = $fileUrl;
        }
        if ($fileType !== null && $fileType !== '') {
            $materialData['file_type'] = $fileType;
        }

        // Nếu không có file_url, không thể insert vào database với constraint NOT NULL
        // Sử dụng DB::table để kiểm soát các fields được insert
        if (!isset($materialData['file_url'])) {
            // Nếu migration chưa chạy, cần có file_url
            // Tạm thời sử dụng empty string hoặc placeholder
            $materialData['file_url'] = ''; // Placeholder cho đến khi migration chạy
        }

        $material = SessionMaterial::create($materialData);

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
