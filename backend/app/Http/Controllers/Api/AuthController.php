<?php

namespace App\Http\Controllers\API; // ✅ ĐÚNG CHỮ HOA

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * POST /api/login
     */
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required'],
        ]);

        if (!Auth::attempt($credentials)) {
            return response()->json(['message' => 'Email hoặc mật khẩu không chính xác.'], 401);
        }

        /** @var User $user */
        $user = User::where('email', $credentials['email'])->firstOrFail();

        // (Tuỳ chọn) Huỷ token cũ: $user->tokens()->delete();
        $token = $user->createToken('api_token')->plainTextToken;

        // Nếu muốn trả kèm hồ sơ tóm tắt lúc login:
        $user->loadMissing(['lecturer.department.faculty']);
        $lec = $user->lecturer;

        return response()->json([
            'token' => $token,
            'user'  => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role'  => $user->role,
            ],
            'lecturer' => $lec ? [
                'gender'        => $lec->gender,
                'date_of_birth' => $lec->date_of_birth,
                'department'    => $lec->department ? [
                    'id'   => $lec->department->id,
                    'name' => $lec->department->name,
                    'faculty' => $lec->department->faculty ? [
                        'id'   => $lec->department->faculty->id,
                        'name' => $lec->department->faculty->name,
                    ] : null,
                ] : null,
            ] : null,
            'avatar_url' => $lec->avatar_url ?? null,
        ]);
    }

    /**
     * GET /api/me
     * Trả profile chuẩn dùng cho app
     */
    public function me(Request $request)
    {
        $user = $request->user()->loadMissing(['lecturer.department.faculty']);
        $lec  = $user->lecturer;

        return response()->json([
            'user' => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role'  => $user->role,
            ],
            'lecturer' => $lec ? [
                'gender'        => $lec->gender,
                'date_of_birth' => $lec->date_of_birth,
                'department'    => $lec->department ? [
                    'id'   => $lec->department->id,
                    'name' => $lec->department->name,
                    'faculty' => $lec->department->faculty ? [
                        'id'   => $lec->department->faculty->id,
                        'name' => $lec->department->faculty->name,
                    ] : null,
                ] : null,
            ] : null,
            'avatar_url' => $lec->avatar_url ?? null,
        ]);
    }

    /**
     * POST /api/logout
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Đăng xuất thành công.']);
    }
}
