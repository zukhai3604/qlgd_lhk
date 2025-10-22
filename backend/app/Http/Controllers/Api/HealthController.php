<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
// thêm dòng sau:
use OpenApi\Attributes as OA;

#[OA\Info(
    title: "QLGD_LHK API",
    version: "1.0.0",
    description: "Tài liệu API hệ thống Quản lý Lịch giảng dạy"
)]
#[OA\Server(
    url: L5_SWAGGER_CONST_HOST,
    description: "Local (Laradock Nginx 8888)"
)]
#[OA\SecurityScheme(
    securityScheme: "bearerAuth",
    type: "http",
    scheme: "bearer",
    bearerFormat: "JWT",
    description: "Use: Bearer {token}"
)]
class HealthController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/health", tags={"System"}, summary="Health check",
     *   @OA\Response(response=200, description="OK",
     *     @OA\JsonContent(
     *       @OA\Property(property="ok", type="boolean", example=true),
     *       @OA\Property(property="time", type="string", format="date-time")
     *     )
     *   )
     * )
     */
    public function health(): JsonResponse {
        return response()->json(['ok'=>true,'time'=>now()]);
    }

    /**
     * @OA\Get(
     *   path="/api/ping", tags={"System"}, summary="Ping",
     *   @OA\Response(response=200, description="OK",
     *     @OA\JsonContent(
     *       @OA\Property(property="pong", type="string", format="date-time")
     *     )
     *   )
     * )
     */
    public function ping(): JsonResponse {
        return response()->json(['pong'=>now()]);
    }
}
