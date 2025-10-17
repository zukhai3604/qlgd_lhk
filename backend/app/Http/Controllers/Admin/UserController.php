<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Lấy danh sách người dùng, có hỗ trợ tìm kiếm và phân trang.
     */
    public function index(Request $request)
    {
        // Bắt đầu một query builder
        $query = User::query();

        // Nếu có tham số 'search' trên URL, thì áp dụng bộ lọc cho tên và email
        if ($request->has('search')) {
            $searchTerm = $request->query('search');
            $query->where(function ($q) use ($searchTerm) {
                $q->where('name', 'like', "%{$searchTerm}%")
                  ->orWhere('email', 'like', "%{$searchTerm}%");
            });
        }

        // Trả về kết quả đã được lọc (nếu có), sắp xếp theo ID giảm dần và phân trang
        return $query->orderByDesc('id')->paginate(20);
    }

    /**
     * Tạo một người dùng mới.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name'      => ['required', 'string', 'max:150'],
            'email'     => ['required', 'email', 'max:190', 'unique:users,email'],
            'phone'     => ['nullable', 'string', 'max:30'],
            'password'  => ['required', 'string', 'min:8'],
            'role'      => ['required', Rule::in(['ADMIN', 'DAO_TAO', 'GIANG_VIEN'])],
            'is_active' => ['boolean']
        ]);

        $data['password'] = bcrypt($data['password']);
        $data['is_active'] = $data['is_active'] ?? true;

        $user = User::create($data);
        return response()->json($user, 201); // 201 Created
    }

    /**
     * Lấy thông tin chi tiết của một người dùng.
     */
    public function show(User $user)
    {
        // Laravel tự động tìm user dựa vào {user} trên URL (Route-Model Binding)
        return $user;
    }

    /**
     * Cập nhật thông tin của một người dùng.
     */
    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name'      => ['sometimes', 'string', 'max:150'],
            'email'     => ['sometimes', 'email', 'max:190', Rule::unique('users', 'email')->ignore($user->id)],
            'phone'     => ['nullable', 'string', 'max:30'],
            'password'  => ['nullable', 'string', 'min:8'], // Mật khẩu không bắt buộc khi cập nhật
            'role'      => ['sometimes', Rule::in(['ADMIN', 'DAO_TAO', 'GIANG_VIEN'])],
            'is_active' => ['boolean']
        ]);

        // Chỉ cập nhật mật khẩu nếu nó được cung cấp
        if (!empty($data['password'])) {
            $data['password'] = bcrypt($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);
        return $user->refresh();
    }

    /**
     * Xóa một người dùng.
     */
    public function destroy(User $user)
    {
        $user->delete();
        return response()->json(['message' => 'User deleted successfully.']);
    }

    /**
     * Khóa tài khoản của một người dùng.
     */
    public function lock(User $user)
    {
        $user->update(['is_active' => false]);
        return response()->json(['message' => 'User locked successfully.']);
    }

    /**
     * Mở khóa tài khoản của một người dùng.
     */
    public function unlock(User $user)
    {
        $user->update(['is_active' => true]);
        return response()->json(['message' => 'User unlocked successfully.']);
    }
}