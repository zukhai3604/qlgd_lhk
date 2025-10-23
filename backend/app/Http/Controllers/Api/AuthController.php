<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use OpenApi\Annotations as OA;

class AuthController extends Controller
{
    /**
     * @OA\Post(
     *   path="/api/login",
     *   operationId="authLogin",
     *   tags={"Auth"},
     *   summary="Đăng nhập và lấy access token",
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"email","password"},
     *       @OA\Property(property="email", type="string", format="email", example="giangvien@qlgd.test"),
     *       @OA\Property(property="password", type="string", example="secret123")
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Đăng nhập thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="token", type="string", example="1|P3nY..."),
     *       @OA\Property(property="user", ref="#/components/schemas/UserResource")
     *     )
     *   ),
     *   @OA\Response(
     *     response=401,
     *     description="Sai thông tin đăng nhập",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Dữ liệu không hợp lệ",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (!Auth::attempt(['email' => $data['email'], 'password' => $data['password']])) {
            return response()->json(['message' => 'Sai tài khoản hoặc mật khẩu'], 401);
        }

        $user = $request->user();
        $token = $user->createToken('api')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user,
        ]);
    }

    /**
     * @OA\Get(
     *   path="/api/me",
     *   operationId="authMe",
     *   tags={"Auth"},
     *   summary="Thông tin người dùng hiện tại",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Thông tin tài khoản",
     *     @OA\JsonContent(ref="#/components/schemas/UserResource")
     *   ),
     *   @OA\Response(
     *     response=401,
     *     description="Chưa xác thực",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function me(Request $request)
    {
        $user = $request->user()->load(['lecturer.department.faculty']);

        return response()->json($user);
    }

    /**
     * @OA\Post(
     *   path="/api/logout",
     *   operationId="authLogout",
     *   tags={"Auth"},
     *   summary="Đăng xuất và thu hồi token hiện tại",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=204,
     *     description="Đăng xuất thành công"
     *   ),
     *   @OA\Response(
     *     response=401,
     *     description="Chưa xác thực",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->noContent();
    }
}
