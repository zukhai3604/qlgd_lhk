<?php

namespace App\OpenApi;

use OpenApi\Annotations as OA;

/**
 * @OA\Info(
 *   version="1.0.0",
 *   title="QLGD API",
 *   description="Tài liệu OpenAPI cho hệ thống Quản lý Giảng dạy."
 * )
 *
 * @OA\Server(
 *   url=L5_SWAGGER_CONST_HOST,
 *   description="Máy chủ API"
 * )
 *
 * @OA\SecurityScheme(
 *   securityScheme="bearerAuth",
 *   type="http",
 *   scheme="bearer",
 *   bearerFormat="JWT",
 *   description="Nhập access token nhận được từ endpoint đăng nhập."
 * )
 */
class Info
{
}
