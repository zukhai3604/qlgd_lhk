<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemReport;
use App\Models\SystemReportAttachment;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SystemReportController extends Controller
{
    public function store(Request $req)
    {
        $validated = $req->validate([
            'source_type'   => ['required', Rule::in(['GIANG_VIEN','DAO_TAO','GUEST'])],
            'title'         => 'required|string|max:200',
            'description'   => 'required|string',
            'category'      => ['nullable', Rule::in(['BUG','FEEDBACK','DATA_ISSUE','PERFORMANCE','SECURITY','OTHER'])],
            'severity'      => ['nullable', Rule::in(['LOW','MEDIUM','HIGH','CRITICAL'])],
            'contact_email' => 'nullable|email',
            // attachments optional: array of {file_url, file_type}
            'attachments'   => 'array',
            'attachments.*.file_url' => 'required|string',
            'attachments.*.file_type'=> 'nullable|string|max:50',
        ]);

        $user = $req->user();
        $report = SystemReport::create([
            'source_type'     => $validated['source_type'],
            'reporter_user_id'=> $user?->id,
            'contact_email'   => $validated['contact_email'] ?? ($user?->email),
            'title'           => $validated['title'],
            'description'     => $validated['description'],
            'category'        => $validated['category'] ?? 'OTHER',
            'severity'        => $validated['severity'] ?? 'LOW',
            'status'          => 'NEW',
            'created_at'      => now(),
        ]);

        if (!empty($validated['attachments'])) {
            foreach ($validated['attachments'] as $att) {
                SystemReportAttachment::create([
                    'report_id'   => $report->id,
                    'file_url'    => $att['file_url'],
                    'file_type'   => $att['file_type'] ?? null,
                    'uploaded_by' => $user?->id,
                    'uploaded_at' => now(),
                ]);
            }
        }

        // Observer sẽ tự tạo Notification
        return response()->json(['data' => $report->load('attachments')], 201);
    }

    // Admin xem danh sách report (lọc/phan trang)
    public function index(Request $req)
    {
        // $this->authorize('viewAny', SystemReport::class); // TODO: tạo Policy nếu cần
        $q = SystemReport::query()
            ->with('reporter:id,name,email','attachments')
            ->when($req->get('status'), fn($qq, $v) => $qq->where('status', $v))
            ->when($req->get('severity'), fn($qq, $v) => $qq->where('severity', $v))
            ->when($req->get('category'), fn($qq, $v) => $qq->where('category', $v))
            ->orderByDesc('created_at');

        return response()->json($q->paginate(20))
            ->header('Content-Type', 'application/json; charset=utf-8');
    }

    // Chi tiết 1 báo cáo
    public function show($id)
    {
        $report = SystemReport::with(['reporter:id,name,email', 'attachments', 'comments.author:id,name', 'closer:id,name'])
            ->findOrFail($id);
        return response()->json(['data' => $report])
            ->header('Content-Type', 'application/json; charset=utf-8');
    }

    // Cập nhật trạng thái
    public function updateStatus(Request $req, $id)
    {
        $validated = $req->validate([
            'status' => ['required', Rule::in(['NEW','IN_REVIEW','ACK','RESOLVED','REJECTED'])],
        ]);

        $report = SystemReport::findOrFail($id);
        $report->status = $validated['status'];
        $report->updated_at = now();
        
        if (in_array($validated['status'], ['RESOLVED', 'REJECTED'])) {
            $report->closed_at = now();
            $report->closed_by = $req->user()->id;
        }
        
        $report->save();
        return response()->json(['data' => $report->fresh(['reporter','closer'])]);
    }

    // Thêm comment
    public function addComment(Request $req, $id)
    {
        $validated = $req->validate([
            'content' => 'required|string',
        ]);

        $report = SystemReport::findOrFail($id);
        $comment = $report->comments()->create([
            'author_user_id' => $req->user()->id,
            'body' => $validated['content'],
            'created_at' => now(),
        ]);

        return response()->json(['data' => $comment->load('author:id,name')], 201);
    }

    // Thống kê tổng quan
    public function statistics()
    {
        $total = SystemReport::count();
        $byStatus = SystemReport::selectRaw('status, count(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');
        
        $bySeverity = SystemReport::selectRaw('severity, count(*) as count')
            ->groupBy('severity')
            ->pluck('count', 'severity');
        
        $byCategory = SystemReport::selectRaw('category, count(*) as count')
            ->groupBy('category')
            ->pluck('count', 'category');

        $recent = SystemReport::with('reporter:id,name')
            ->orderByDesc('created_at')
            ->take(5)
            ->get();

        return response()->json([
            'total' => $total,
            'by_status' => $byStatus,
            'by_severity' => $bySeverity,
            'by_category' => $byCategory,
            'recent' => $recent,
        ])->header('Content-Type', 'application/json; charset=utf-8');
    }
}
