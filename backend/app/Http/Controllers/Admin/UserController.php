<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

/** @OA\Tag(name="Admin - Users", description="Quản lý người dùng (ADMIN)") */
class UserController extends Controller
{
    /** @OA\Get(
     *  path="/api/admin/users", tags={"Admin - Users"}, summary="Danh sách người dùng",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="page", in="query", @OA\Schema(type="integer")),
     *  @OA\Response(response=200, description="OK", @OA\JsonContent(ref="#/components/schemas/PaginatedUsers"))
     * ) */
    public function index()
    {
        return User::paginate(15);
    }

    /** @OA\Post(
     *  path="/api/admin/users", tags={"Admin - Users"}, summary="Tạo người dùng",
     *  security={{"bearerAuth":{}}},
     *  @OA\RequestBody(required=true, @OA\JsonContent(
     *    required={"name","email","password","role"},
     *    @OA\Property(property="name", type="string"),
     *    @OA\Property(property="email", type="string", format="email"),
     *    @OA\Property(property="password", type="string", format="password"),
     *    @OA\Property(property="role", type="string", example="GIANG_VIEN")
     *  )),
     *  @OA\Response(response=201, description="Created", @OA\JsonContent(ref="#/components/schemas/User"))
     * ) */
    public function store(Request $request)
    {
        // Logic tạo user
    }

    /** @OA\Get(
     *  path="/api/admin/users/{id}", tags={"Admin - Users"}, summary="Chi tiết người dùng",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *  @OA\Response(response=200, description="OK", @OA\JsonContent(ref="#/components/schemas/User")),
     *  @OA\Response(response=404, description="Not Found", @OA\JsonContent(ref="#/components/schemas/Error"))
     * ) */
    public function show(User $user)
    {
        return $user;
    }

    /** @OA\Put(
     *  path="/api/admin/users/{id}", tags={"Admin - Users"}, summary="Cập nhật người dùng",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *  @OA\RequestBody(@OA\JsonContent(
     *    @OA\Property(property="name", type="string"),
     *    @OA\Property(property="email", type="string", format="email"),
     *    @OA\Property(property="role", type="string")
     *  )),
     *  @OA\Response(response=200, description="OK", @OA\JsonContent(ref="#/components/schemas/User"))
     * ) */
    public function update(Request $request, User $user)
    {
        // Logic cập nhật user
    }

    /** @OA\Delete(
     *  path="/api/admin/users/{id}", tags={"Admin - Users"}, summary="Xoá người dùng",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *  @OA\Response(response=204, description="No Content")
     * ) */
    public function destroy(User $user)
    {
        // Logic xoá user
    }
}
