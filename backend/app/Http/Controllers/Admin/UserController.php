<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

/**
 * @OA\Tag(
 *   name="Admin - Users",
 *   description="Quản lý tài khoản người dùng (vai trò ADMIN)"
 * )
 */
class UserController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/admin/users",
     *   operationId="adminUsersIndex",
     *   tags={"Admin - Users"},
     *   summary="Danh sách người dùng",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="page", in="query", @OA\Schema(type="integer")),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách phân trang",
     *     @OA\JsonContent(ref="#/components/schemas/PaginatedUsers")
     *   )
     * )
     */
    public function index()
    {
        return User::paginate(15);
    }

    /**
     * @OA\Post(
     *   path="/api/admin/users",
     *   operationId="adminUsersStore",
     *   tags={"Admin - Users"},
     *   summary="Tạo người dùng mới",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"name","email","password","role"},
     *       @OA\Property(property="name", type="string", example="Nguyễn Văn A"),
     *       @OA\Property(property="email", type="string", format="email", example="admin@qlgd.test"),
     *       @OA\Property(property="password", type="string", format="password", example="secret123"),
     *       @OA\Property(property="role", type="string", example="GIANG_VIEN"),
     *       @OA\Property(property="phone", type="string", nullable=true),
     *       @OA\Property(property="is_active", type="boolean", example=true)
     *     )
     *   ),
     *   @OA\Response(
     *     response=201,
     *     description="Tạo thành công",
     *     @OA\JsonContent(ref="#/components/schemas/UserResource")
     *   ),
     *   @OA\Response(response=422, description="Dữ liệu không hợp lệ", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function store(Request $request)
    {
        // TODO: Hiện tại controller chỉ là demo. Thêm logic tạo user nếu cần.
    }

    /**
     * @OA\Get(
     *   path="/api/admin/users/{id}",
     *   operationId="adminUsersShow",
     *   tags={"Admin - Users"},
     *   summary="Chi tiết người dùng",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(
     *     response=200,
     *     description="Thông tin người dùng",
     *     @OA\JsonContent(ref="#/components/schemas/UserResource")
     *   ),
     *   @OA\Response(response=404, description="Không tìm thấy", @OA\JsonContent(ref="#/components/schemas/ErrorResponse"))
     * )
     */
    public function show(User $user)
    {
        return $user;
    }

    /**
     * @OA\Put(
     *   path="/api/admin/users/{id}",
     *   operationId="adminUsersUpdate",
     *   tags={"Admin - Users"},
     *   summary="Cập nhật người dùng",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     @OA\JsonContent(
     *       @OA\Property(property="name", type="string"),
     *       @OA\Property(property="email", type="string", format="email"),
     *       @OA\Property(property="role", type="string"),
     *       @OA\Property(property="phone", type="string", nullable=true),
     *       @OA\Property(property="is_active", type="boolean", nullable=true)
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Cập nhật thành công",
     *     @OA\JsonContent(ref="#/components/schemas/UserResource")
     *   )
     * )
     */
    public function update(Request $request, User $user)
    {
        // TODO: Bổ sung logic cập nhật user nếu cần.
    }

    /**
     * @OA\Delete(
     *   path="/api/admin/users/{id}",
     *   operationId="adminUsersDestroy",
     *   tags={"Admin - Users"},
     *   summary="Xóa người dùng",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=204, description="Đã xóa")
     * )
     */
    public function destroy(User $user)
    {
        // TODO: Bổ sung logic xóa user nếu cần.
    }
}
