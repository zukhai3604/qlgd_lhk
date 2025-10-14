<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;                      // <-- SỬA LỖI: THÊM DÒNG NÀY
use Illuminate\Support\Facades\Auth;      // <-- SỬA LỖI: THÊM DÒNG NÀY

class AuthController extends Controller
{
    // SỬA LỖI: HÀM LOGIN PHẢI NẰM BÊN TRONG CẶP DẤU {} CỦA CLASS
    public function login(Request $request)
    {
        // 1. Kiểm tra dữ liệu đầu vào (email, password) có hợp lệ không
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // 2. Thử xác thực người dùng với thông tin đã cung cấp
        if (!Auth::attempt($credentials)) {
            // Nếu sai email hoặc password, trả về lỗi
            return response()->json([
                'message' => 'Email hoặc mật khẩu không chính xác.'
            ], 401); // 401 Unauthorized
        }

        // 3. Xác thực thành công, lấy thông tin user
        $user = User::where('email', $request->email)->first();

        // 4. Tạo ra một token mới cho user này
        $token = $user->createToken('api_token')->plainTextToken;

        // 5. Trả về thông tin user và token cho client (app mobile)
        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    // (Các hàm me() và logout() mà chúng ta đã làm trước đó sẽ nằm ở đây)
    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Đăng xuất thành công.']);
    }
}