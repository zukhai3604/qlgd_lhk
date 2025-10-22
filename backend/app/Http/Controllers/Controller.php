<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use OpenApi\Annotations as OA;

/**
 * @OA\Info(
 *   title="QLGD_LHK API",
 *   version="1.0.0",
 *   description="Tài liệu API hệ thống Quản lý Lịch giảng dạy"
 * )
 * @OA\Server(
 *   url=L5_SWAGGER_CONST_HOST,
 *   description="Local (Laradock Nginx 8888)"
 * )
 * @OA\SecurityScheme(
 *   securityScheme="bearerAuth",
 *   type="http",
 *   scheme="bearer",
 *   bearerFormat="JWT",
 *   description="Use: Bearer {token}"
 * )
 */

/**
 * @OA\Schema(schema="User",
 *  @OA\Property(property="id", type="integer", example=1),
 *  @OA\Property(property="name", type="string", example="Nguyen Van A"),
 *  @OA\Property(property="email", type="string", format="email", example="lecturer@tlu.edu.vn"),
 *  @OA\Property(property="role", type="string", example="GIANG_VIEN")
 * )
 *
 * @OA\Schema(schema="Error",
 *  @OA\Property(property="message", type="string"),
 *  @OA\Property(property="errors", type="object", nullable=true)
 * )
 *
 * @OA\Schema(schema="PaginatedUsers",
 *  @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/User")),
 *  @OA\Property(property="links", type="object"),
 *  @OA\Property(property="meta", type="object")
 * )
 */

class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;
}
