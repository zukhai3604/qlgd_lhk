<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\MakeupRequestStoreRequest;
use App\Http\Requests\Lecturer\MakeupRequestUpdateRequest;
use App\Http\Resources\Lecturer\MakeupRequestResource;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use App\Models\Notification;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class MakeupRequestController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/makeup-requests",
     *   operationId="lecturerMakeupIndex",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Danh sách đề xuất dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phân trang",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(ref="#/components/schemas/MakeupRequestResource")
     *       ),
     *       @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
     *     )
     *   )
     * )
     */
    public function index(Request $request)
    {
        try {
            $lecturerId = optional($request->user()->lecturer)->id;
            
            if (!$lecturerId) {
                return response()->json([
                    'data' => [],
                    'links' => [],
                    'meta' => ['total' => 0, 'current_page' => 1, 'last_page' => 1],
                ]);
            }

            // Đơn giản hóa: Eager load tất cả relationships ngay từ đầu giống LeaveRequestController
            $items = MakeupRequest::query()
                ->with([
                    'leave.schedule.assignment.subject',
                    'leave.schedule.assignment.classUnit',
                    'leave.schedule.timeslot',
                    'leave.schedule.room',
                    'timeslot',
                    'room',
                ])
                ->whereHas('leave', function ($builder) use ($lecturerId) {
                    $builder->where('lecturer_id', $lecturerId);
                })
                ->orderByDesc('id')
                ->paginate(20);
            
            // Use Resource collection like LeaveRequestController (simpler approach)
            return MakeupRequestResource::collection($items)
                ->additional(['meta' => ['total' => $items->total()]]);
        } catch (\Exception $e) {
            \Log::error('MakeupRequestController::index - Exception', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            // Fallback: return empty response to prevent connection error
            try {
                $lecturerId = optional($request->user()->lecturer)->id ?? null;
                if ($lecturerId) {
                    $items = MakeupRequest::query()
                        ->whereHas('leave', function ($builder) use ($lecturerId) {
                            $builder->where('lecturer_id', $lecturerId);
                        })
                        ->orderByDesc('id')
                        ->paginate(20);
                    
                    return response()->json([
                        'data' => $items->map(function ($item) {
                            return [
                                'id' => $item->id,
                                'leave_request_id' => $item->leave_request_id,
                                'suggested_date' => $item->suggested_date?->format('Y-m-d'),
                                'timeslot_id' => $item->timeslot_id,
                                'room_id' => $item->room_id,
                                'note' => $item->note,
                                'status' => $item->status,
                                'subject' => '',
                                'subject_name' => '',
                                'class_name' => '',
                                'start_time' => '',
                                'end_time' => '',
                                'timeslot' => null,
                                'room' => null,
                                'leave' => null,
                            ];
                        })->values()->all(),
                        'links' => [
                            'first' => $items->url(1),
                            'last' => $items->url($items->lastPage()),
                            'prev' => $items->previousPageUrl(),
                            'next' => $items->nextPageUrl(),
                        ],
                        'meta' => [
                            'current_page' => $items->currentPage(),
                            'from' => $items->firstItem(),
                            'last_page' => $items->lastPage(),
                            'path' => $items->path(),
                            'per_page' => $items->perPage(),
                            'to' => $items->lastItem(),
                            'total' => $items->total(),
                        ],
                    ]);
                }
            } catch (\Exception $e2) {
                \Log::error('MakeupRequestController::index - Fallback also failed', [
                    'error' => $e2->getMessage(),
                ]);
            }
            
            // Final fallback: return empty response
            return response()->json([
                'data' => [],
                'links' => [],
                'meta' => [
                    'total' => 0,
                    'current_page' => 1,
                    'last_page' => 1,
                    'from' => null,
                    'to' => null,
                ],
            ]);
        }
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/makeup-requests",
     *   operationId="lecturerMakeupStore",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Đề xuất buổi dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"leave_request_id","suggested_date","timeslot_id"},
     *       @OA\Property(property="leave_request_id", type="integer", example=100),
     *       @OA\Property(property="suggested_date", type="string", format="date", example="2025-10-28"),
     *       @OA\Property(property="timeslot_id", type="integer", example=4),
     *       @OA\Property(property="room_id", type="integer", nullable=true, example=12),
     *       @OA\Property(property="note", type="string", nullable=true, example="Ưu tiên phòng lab")
     *     )
     *   ),
     *   @OA\Response(
     *     response=201,
     *     description="Tạo đề xuất dạy bù thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy đơn nghỉ", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=422, description="Dữ liệu không hợp lệ", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function store(MakeupRequestStoreRequest $request)
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        $data = $request->validated();

        $leave = LeaveRequest::find($data['leave_request_id']);
        if (!$leave) {
            return response()->json(['message' => 'Không tìm thấy yêu cầu nghỉ'], 404);
        }
        if ($leave->lecturer_id !== $lecturerId) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        $makeup = new MakeupRequest($data);
        $makeup->status = 'PENDING';
        $makeup->save();

        // Tạo thông báo cho giảng viên về việc đã gửi đề xuất dạy bù
        try {
            $user = $request->user();
            $title = 'Đã gửi đề xuất dạy bù';
            $date = $data['suggested_date'] ?? null;
            $slot = isset($data['timeslot_id']) ? ('Ca: ' . $data['timeslot_id']) : null; // có thể map tên ca nếu cần
            $body = trim(implode(' ', array_filter([
                $date ? "Ngày dạy bù: $date" : null,
                $slot,
            ])));

            Notification::create([
                'from_user_id' => $user->id,
                'to_user_id'   => $user->id,
                'title'        => $title,
                'body'         => $body,
                'type'         => 'MAKEUP_REQUEST',
                'status'       => 'UNREAD',
                'created_at'   => now(),
            ]);
        } catch (\Throwable $e) {
            // fail-safe
        }

        return response()->json(['data' => new MakeupRequestResource($makeup)], 201);
    }

    /**
     * @OA\Get(
     *   path="/api/lecturer/makeup-requests/{id}",
     *   operationId="lecturerMakeupShow",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Chi tiết đề xuất dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=200)),
     *   @OA\Response(
     *     response=200,
     *     description="Chi tiết đề xuất",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function show(Request $request, int $id)
    {
        $makeup = MakeupRequest::with('leave')->find($id);
        if (!$makeup) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($makeup->leave?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }

        return response()->json(['data' => new MakeupRequestResource($makeup)]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/makeup-requests/{id}",
     *   operationId="lecturerMakeupUpdate",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Chỉnh sửa đề xuất dạy bù (khi còn PENDING)",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=200)),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="suggested_date", type="string", format="date", example="2025-10-30"),
     *       @OA\Property(property="timeslot_id", type="integer", example=5),
     *       @OA\Property(property="room_id", type="integer", nullable=true, example=9),
     *       @OA\Property(property="note", type="string", nullable=true, example="Đề xuất phòng đa năng")
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Cập nhật thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/MakeupRequestResource")
     *     )
     *   ),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=422, description="Chỉ chỉnh sửa khi PENDING", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function update(MakeupRequestUpdateRequest $request, int $id)
    {
        $makeup = MakeupRequest::with('leave')->find($id);
        if (!$makeup) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($makeup->leave?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }
        if ($makeup->status !== 'PENDING') {
            return response()->json(['message' => 'Chỉ chỉnh sửa khi đề xuất còn PENDING'], 422);
        }

        $makeup->fill($request->validated());
        $makeup->save();

        return response()->json(['data' => new MakeupRequestResource($makeup)]);
    }

    /**
     * @OA\Delete(
     *   path="/api/lecturer/makeup-requests/{id}",
     *   operationId="lecturerMakeupDestroy",
     *   tags={"Lecturer - Dạy bù"},
     *   summary="Hủy đề xuất dạy bù",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer", example=200)),
     *   @OA\Response(response=204, description="Đã hủy"),
     *   @OA\Response(response=403, description="Không có quyền", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse")),
     *   @OA\Response(response=422, description="Chỉ hủy khi PENDING", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function destroy(Request $request, int $id)
    {
        $makeup = MakeupRequest::with('leave')->find($id);
        if (!$makeup) {
            return response()->json(['message' => 'Không tìm thấy'], 404);
        }
        if ($makeup->leave?->lecturer_id !== optional($request->user()->lecturer)->id) {
            return response()->json(['message' => 'Không có quyền'], 403);
        }
        if ($makeup->status !== 'PENDING') {
            return response()->json(['message' => 'Chỉ hủy được đề xuất còn PENDING'], 422);
        }

        $makeup->delete();

        return response()->noContent();
    }
}
