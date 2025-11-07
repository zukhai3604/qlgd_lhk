<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use OpenApi\Annotations as OA;

class HealthController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/health",
     *   tags={"System"},
     *   summary="Kiểm tra tình trạng dịch vụ",
     *   @OA\Response(
     *     response=200,
     *     description="Dịch vụ hoạt động bình thường",
     *     @OA\JsonContent(
     *       @OA\Property(property="ok", type="boolean", example=true),
     *       @OA\Property(property="time", type="string", format="date-time", example="2025-10-22T13:45:00+07:00")
     *     )
     *   )
     * )
     */
    public function health(): JsonResponse
    {
        return response()->json([
            'ok' => true,
            'time' => now(),
        ]);
    }

    /**
     * @OA\Get(
     *   path="/api/ping",
     *   tags={"System"},
     *   summary="Ping thử kết nối",
     *   @OA\Response(
     *     response=200,
     *     description="Trả về dấu thời gian hiện tại",
     *     @OA\JsonContent(
     *       @OA\Property(property="pong", type="string", format="date-time", example="2025-10-22T13:45:00+07:00")
     *     )
     *   )
     * )
     */
    public function ping(): JsonResponse
    {
        return response()->json([
            'pong' => now(),
        ]);
    }
}
