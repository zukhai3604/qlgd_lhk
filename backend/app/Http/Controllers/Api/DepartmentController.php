<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class DepartmentController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/departments",
     *   operationId="listDepartments",
     *   tags={"Danh mục"},
     *   summary="Danh sách bộ môn",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="faculty_id",
     *     in="query",
     *     description="Lọc theo khoa",
     *     required=false,
     *     @OA\Schema(type="integer", example=1)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách bộ môn",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="id", type="integer", example=10),
     *           @OA\Property(property="code", type="string", example="HTTT"),
     *           @OA\Property(property="name", type="string", example="Bộ môn Hệ thống Thông tin"),
     *           @OA\Property(
     *             property="faculty",
     *             type="object",
     *             @OA\Property(property="id", type="integer", example=1),
     *             @OA\Property(property="code", type="string", example="CNTT"),
     *             @OA\Property(property="name", type="string", example="Khoa Công nghệ Thông tin")
     *           )
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
        $query = Department::query()
            ->with('faculty:id,code,name')
            ->orderBy('name')
            ->select(['id', 'code', 'name', 'faculty_id']);

        if ($request->filled('faculty_id')) {
            $query->where('faculty_id', $request->integer('faculty_id'));
        }

        return response()->json(['data' => $query->get()]);
    }
}
