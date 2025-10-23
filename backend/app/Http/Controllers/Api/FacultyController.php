<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faculty;
use OpenApi\Annotations as OA;

class FacultyController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/faculties",
     *   operationId="listFaculties",
     *   tags={"Danh mục"},
     *   summary="Danh sách khoa",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách khoa",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="id", type="integer", example=1),
     *           @OA\Property(property="code", type="string", example="CNTT"),
     *           @OA\Property(property="name", type="string", example="Khoa Công nghệ Thông tin")
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
    public function index()
    {
        $faculties = Faculty::query()
            ->orderBy('name')
            ->get(['id', 'code', 'name']);

        return response()->json(['data' => $faculties]);
    }
}
