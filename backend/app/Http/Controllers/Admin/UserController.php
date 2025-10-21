<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Lấy danh sách người dùng, có hỗ trợ tìm kiếm và phân trang.
     * API: GET /api/admin/users?search=...&page=...
     */
    public function index(Request $request)
    {
        $query = User::query();

        // Xử lý tìm kiếm
        if ($request->has('search')) {
            $searchTerm = $request->query('search');
            $query->where(function ($q) use ($searchTerm) {
                $q->where('name', 'like', "%{$searchTerm}%")
                  ->orWhere('email', 'like', "%{$searchTerm}%")
                  ->orWhere('phone', 'like', "%{$searchTerm}%");
            });
        }

        // Sắp xếp và phân trang
        return $query->orderByDesc('id')->paginate(20);
    }

    /**
     * Tạo một người dùng mới.
     * API: POST /api/admin/users
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name'          => ['required', 'string', 'max:150'],
            'email'         => ['required', 'email', 'max:190', 'unique:users,email'],
            'phone'         => ['nullable', 'string', 'max:30'],
            'password'      => ['required', 'string', 'min:8'],
            'role'          => ['required', Rule::in(['ADMIN', 'DAO_TAO', 'GIANG_VIEN'])],
            'is_active'     => ['boolean'],
            'date_of_birth' => ['nullable', 'date_format:Y-m-d'],
            'gender'        => ['nullable', 'string', Rule::in(['Nam', 'Nữ', 'Khác'])],
            'department'    => ['nullable', 'string', 'max:190'],
            'faculty'       => ['nullable', 'string', 'max:190'],
            'avatar'        => ['nullable', 'string', 'max:500', 'url'],
        ]);

        $data['password'] = Hash::make($data['password']);
        $data['is_active'] = $data['is_active'] ?? true;

        $user = User::create($data);
        return response()->json($user, 201); // 201 Created
    }

    /**
     * Lấy thông tin chi tiết của một người dùng.
     * API: GET /api/admin/users/{user}
     */
    public function show(User $user)
    {
        return $user;
    }

    /**
     * Cập nhật thông tin của một người dùng.
     * API: PUT /api/admin/users/{user}
     */
    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name'          => ['sometimes', 'string', 'max:150'],
            'email'         => ['sometimes', 'email', 'max:190', Rule::unique('users', 'email')->ignore($user->id)],
            'phone'         => ['nullable', 'string', 'max:30'],
            'password'      => ['nullable', 'string', 'min:8'], // Mật khẩu không bắt buộc khi cập nhật
            'role'          => ['sometimes', Rule::in(['ADMIN', 'DAO_TAO', 'GIANG_VIEN'])],
            'is_active'     => ['boolean'],
            'date_of_birth' => ['nullable', 'date_format:Y-m-d'],
            'gender'        => ['nullable', 'string', Rule::in(['Nam', 'Nữ', 'Khác'])],
            'department'    => ['nullable', 'string', 'max:190'],
            'faculty'       => ['nullable', 'string', 'max:190'],
            'avatar'        => ['nullable', 'string', 'max:500', 'url'],
        ]);

        // Chỉ cập nhật mật khẩu nếu nó được cung cấp và không rỗng
        if (!empty($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']); // Xóa key password khỏi mảng data nếu không cập nhật
        }

        $user->update($data);
        return $user->refresh(); // Trả về user sau khi đã cập nhật
    }

    /**
     * Xóa một người dùng.
     * API: DELETE /api/admin/users/{user}
     */
    public function destroy(User $user)
    {
        $user->delete();
        return response()->json(['message' => 'User deleted successfully.']);
    }

    /**
     * Khóa tài khoản của một người dùng.
     * API: POST /api/admin/users/{user}/lock
     */
    public function lock(User $user)
    {
        $user->update(['is_active' => false]);
        return response()->json(['message' => 'User locked successfully.']);
    }

    /**
     * Mở khóa tài khoản của một người dùng.
     * API: POST /api/admin/users/{user}/unlock
     */
    public function unlock(User $user)
    {
        $user->update(['is_active' => true]);
        return response()->json(['message' => 'User unlocked successfully.']);
    }

    // ==========================================================
    // ===== HÀM MỚI BẠN CẦN THÊM VÀO LÀ HÀM NÀY (ADMIN) =====
    // ==========================================================
    
    /**
     * [Admin] Đặt lại mật khẩu cho một người dùng.
     * API: POST /api/admin/users/{user}/reset-password
     */
    public function resetPassword(Request $request, User $user)
    {
        // 1. Validate mật khẩu mới
        $data = $request->validate([
            'password' => ['required', 'string', 'min:8'],
        ]);

        // 2. Cập nhật mật khẩu mới (đã hash)
        $user->update([
            'password' => Hash::make($data['password'])
        ]);
        
        // 3. Trả về thông báo thành công
        return response()->json(['message' => 'Password for user ' . $user->name . ' has been reset successfully.']);
    }
}