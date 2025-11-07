<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    /**
     * Cập nhật mật khẩu cho người dùng đang đăng nhập.
     */
    public function updatePassword(Request $request)
    {
        $user = $request->user();

        // 1. Validate dữ liệu đầu vào
        $request->validate([
            'current_password' => ['required', 'current_password'],
            'new_password'     => ['required', 'confirmed', Password::min(8)],
        ]);

        // 2. Cập nhật mật khẩu mới đã được băm
        $user->update([
            'password' => Hash::make($request->input('new_password'))
        ]);

        // 3. Trả về thông báo thành công
        return response()->json(['message' => 'Password updated successfully.']);
    }
}