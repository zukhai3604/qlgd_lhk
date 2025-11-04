<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Room;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class RoomController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/rooms",
     *   operationId="listRooms",
     *   tags={"Danh mục"},
     *   summary="Danh sách phòng học",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phòng học",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="id", type="integer", example=22),
     *           @OA\Property(property="code", type="string", example="A118"),
     *           @OA\Property(property="building", type="string", nullable=true, example="Nhà A"),
     *           @OA\Property(property="capacity", type="integer", nullable=true, example=50),
     *           @OA\Property(property="room_type", type="string", enum={"LT","TH","LAB","OTHER"}, example="LT")
     *         )
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=401,
     *     description="Chưa xác thực",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function index(Request $request)
    {
        try {
            $rooms = Room::query()
                ->orderBy('code')
                ->get(['id', 'code', 'building', 'capacity', 'room_type'])
                ->map(function ($room) {
                    return [
                        'id' => $room->id,
                        'code' => $room->code ?? '',
                        'building' => $room->building,
                        'capacity' => $room->capacity,
                        'room_type' => $room->room_type ?? 'LT',
                    ];
                })
                ->values()
                ->toArray();

            return response()->json(['data' => $rooms]);
        } catch (\Exception $e) {
            \Log::error('RoomController::index error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'message' => 'Đã có lỗi xảy ra khi lấy danh sách phòng',
                'error' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }
}

