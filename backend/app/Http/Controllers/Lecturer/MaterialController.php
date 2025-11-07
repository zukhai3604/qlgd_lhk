<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
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
            
            if (!$path) {
                return response()->json([
                    'message' => 'Không thể upload file. Vui lòng thử lại.'
                ], 400);
            }
            
            // Sử dụng Storage::url() để lấy URL đúng
            $fileUrl = Storage::disk('public')->url($path);
            
            // Fallback nếu Storage::url() không hoạt động
            if (empty($fileUrl)) {
                $fileUrl = url('storage/' . $path);
            }
        } elseif ($request->filled('file_url')) {
            // Cho phép nhập URL từ bên ngoài (Google Drive, OneDrive, etc.)
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
        if ($fileUrl !== null && $fileUrl !== '') {
            $materialData['file_url'] = $fileUrl;
        }
        if ($fileType !== null && $fileType !== '') {
            $materialData['file_type'] = $fileType;
        }

        // Với migration đã chạy, file_url có thể NULL
        // Nhưng để đảm bảo có nội dung, yêu cầu phải có file hoặc URL
        // (Có thể bỏ comment dòng này nếu muốn cho phép material không có file)
        // if (!isset($materialData['file_url'])) {
        //     return response()->json([
        //         'message' => 'Vui lòng upload file hoặc cung cấp URL tài liệu.'
        //     ], 400);
        // }

        $material = SessionMaterial::create($materialData);

        return response()->json([
            'message' => 'Đã thêm nội dung/tài liệu.',
            'data'    => $material->only(['id','title','file_url','file_type','uploaded_by','uploaded_at']),
        ], 201);
    }

    /**
     * DELETE /api/lecturer/schedule/{id}/materials/{materialId}
     */
    public function destroy(Request $request, $id, $materialId)
    {
        $user = $request->user();

        $schedule = Schedule::with('assignment.lecturer.user')->findOrFail($id);
        abort_if(optional($schedule->assignment?->lecturer?->user)->id !== $user->id, 403);

        $mat = SessionMaterial::where('schedule_id', $id)->findOrFail($materialId);
        
        // Xóa file nếu có
        if ($mat->file_url) {
            // Lấy path từ URL (bỏ phần domain)
            $path = str_replace(Storage::disk('public')->url(''), '', $mat->file_url);
            if ($path && Storage::disk('public')->exists($path)) {
                Storage::disk('public')->delete($path);
            }
        }
        
        $mat->delete();

        return response()->json(['message' => 'Đã xoá tài liệu.']);
    }
}
