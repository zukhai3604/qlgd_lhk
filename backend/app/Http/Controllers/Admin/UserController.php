<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Admin;
use App\Models\TrainingStaff;
use App\Models\Lecturer;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * @OA\Tag(
 *   name="Admin - Users",
 *   description="Quản lý tài khoản người dùng (vai trò ADMIN)"
 * )
 */
class UserController extends Controller
{
    /**
     * GET /api/admin/users
     * Danh sách người dùng (trừ chính mình), có tìm kiếm + lọc role + phân trang.
     */
    public function index(Request $request)
    {
        try {
            $query = User::with(['admin', 'trainingStaff', 'lecturer'])
                ->where('id', '!=', auth()->id());

            if ($request->filled('role')) {
                $query->where('role', $request->string('role'));
            }

            if ($request->filled('search')) {
                $search = $request->string('search');
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }

            $perPage = (int) $request->get('per_page', 15);
            $users = $query->paginate($perPage);

            return response()->json($users);
        } catch (\Throwable $e) {
            Log::error('Error fetching users: '.$e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'message' => 'Failed to fetch users',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/admin/users
     * Tạo tài khoản mới; nếu không gửi password sẽ tự sinh.
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name'         => ['required','string','max:255'],
                'email'        => ['required','email','max:190','unique:users,email'],
                'phone'        => ['nullable','string','max:32'],
                'role'         => ['required', Rule::in(['ADMIN','DAO_TAO','GIANG_VIEN'])],
                'password'     => ['nullable','string','min:8'],
                'force_change' => ['sometimes','boolean'],
            ]);

            $plainPassword = $validated['password'] ?? Str::random(10);

            $user = User::create([
                'name'     => $validated['name'],
                'email'    => $validated['email'],
                'phone'    => $validated['phone'] ?? null,
                'password' => Hash::make($plainPassword),
                'role'     => $validated['role'],
                'is_active'=> true,
            ]);

            // tạo bản ghi theo role
            $this->ensureRoleModels($user);

            // Gắn cờ bắt đổi mật khẩu lần đầu nếu có cột này
            if (!empty($validated['force_change'])) {
                if (Schema::hasColumn('users', 'force_change_password')) {
                    $user->force_change_password = true;
                    $user->save();
                }
            }

            return response()->json([
                'message' => 'Tạo tài khoản thành công',
                'data' => [
                    'id'                 => $user->id,
                    'name'               => $user->name,
                    'email'              => $user->email,
                    'role'               => $user->role,
                    'temporary_password' => $plainPassword,
                ],
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Error creating user: '.$e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'message' => 'Failed to create user',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/admin/users/{id}
     * Xem chi tiết user.
     */
    public function show($id)
    {
        try {
            $user = User::with(['admin', 'trainingStaff', 'lecturer'])->findOrFail($id);

            return response()->json([
                'data' => $user,
            ]);
        } catch (\Throwable $e) {
            Log::error('Error fetching user details: '.$e->getMessage());
            return response()->json([
                'message' => 'User not found',
                'error'   => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * PATCH /api/admin/users/{id}
     * Cập nhật thông tin cơ bản.
     */
    public function update(Request $request, $id)
    {
        try {
            $user = User::findOrFail($id);

            $validated = $request->validate([
                'name'      => ['sometimes','string','max:255'],
                'email'     => ['sometimes','email', Rule::unique('users')->ignore($id)],
                'role'      => ['sometimes', Rule::in(['ADMIN','DAO_TAO','GIANG_VIEN'])],
                'is_active' => ['sometimes','boolean'],
                'phone'     => ['sometimes','nullable','string','max:32'],
            ]);

            $user->update($validated);

            // Nếu có đổi role qua PATCH chung, vẫn đảm bảo record role tồn tại
            if (isset($validated['role'])) {
                $this->ensureRoleModels($user->refresh());
            }

            $user->load(['admin', 'trainingStaff', 'lecturer']);

            return response()->json([
                'message' => 'User updated successfully',
                'data'    => $user,
            ]);
        } catch (\Throwable $e) {
            Log::error('Error updating user: '.$e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'message' => 'Failed to update user',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * DELETE /api/admin/users/{id}
     */
    public function destroy($id)
    {
        try {
            $user = User::findOrFail($id);

            if ($user->id === auth()->id()) {
                return response()->json([
                    'message' => 'You cannot delete your own account',
                ], 403);
            }

            $user->delete();

            return response()->json([
                'message' => 'User deleted successfully',
            ]);
        } catch (\Throwable $e) {
            Log::error('Error deleting user: '.$e->getMessage());
            return response()->json([
                'message' => 'Failed to delete user',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/admin/users/{id}/lock
     */
    public function lock($id)
    {
        try {
            $user = User::findOrFail($id);

            if ($user->id === auth()->id()) {
                return response()->json([
                    'message' => 'You cannot lock your own account',
                ], 403);
            }

            $user->update(['is_active' => false]);

            return response()->json([
                'message' => 'User locked successfully',
                'data'    => $user,
            ]);
        } catch (\Throwable $e) {
            Log::error('Error locking user: '.$e->getMessage());
            return response()->json([
                'message' => 'Failed to lock user',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/admin/users/{id}/unlock
     */
    public function unlock($id)
    {
        try {
            $user = User::findOrFail($id);
            $user->update(['is_active' => true]);

            return response()->json([
                'message' => 'User unlocked successfully',
                'data'    => $user,
            ]);
        } catch (\Throwable $e) {
            Log::error('Error unlocking user: '.$e->getMessage());
            return response()->json([
                'message' => 'Failed to unlock user',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/admin/users/{id}/reset-password
     * FE đang gọi với { temporary_password?: string, force_change?: bool }
     */
    public function resetPassword(Request $request, $id)
    {
        try {
            $user = User::findOrFail($id);

            $validated = $request->validate([
                'temporary_password' => ['nullable','string','min:8'],
                'password'           => ['sometimes','string','min:8','confirmed'], // optional legacy path
                'force_change'       => ['sometimes','boolean'],
            ]);

            // Ưu tiên 'password' + confirmation nếu được gửi theo chuẩn cũ
            if (!empty($validated['password'])) {
                $plain = $validated['password'];
            } else {
                $plain = $validated['temporary'] ?? $validated['temporary_password'] ?? Str::random(10);
            }

            $user->password = Hash::make($plain);

            if (!empty($validated['force_change']) && Schema::hasColumn('users','force_change_password')) {
                $user->force_change_password = true;
            }

            $user->save();

            return response()->json([
                'message'       => 'Password reset successfully',
                'new_password'  => $plain, // để FE hiển thị/copy
            ]);
        } catch (\Throwable $e) {
            Log::error('Error resetting password: '.$e->getMessage());
            return response()->json([
                'message' => 'Failed to reset password',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/admin/users/{id}/role
     * Cập nhật vai trò, đảm bảo tạo record role tương ứng.
     */
    public function updateRole(Request $request, $id)
    {
        try {
            $user = User::findOrFail($id);

            $validated = $request->validate([
                'role' => ['required', Rule::in(['ADMIN','DAO_TAO','GIANG_VIEN'])],
            ]);

            $user->role = $validated['role'];
            $user->save();

            $this->ensureRoleModels($user);

            $user->load(['admin','trainingStaff','lecturer']);

            return response()->json([
                'message' => 'Role updated successfully',
                'data'    => $user,
            ]);
        } catch (\Throwable $e) {
            Log::error('Error updating role: '.$e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'message' => 'Failed to update role',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Đảm bảo bản ghi phụ trợ theo role tồn tại (Admin / TrainingStaff / Lecturer).
     */
    protected function ensureRoleModels(User $user): void
    {
        try {
            if ($user->role === 'ADMIN') {
                if (!$user->admin) {
                    Admin::firstOrCreate(['user_id' => $user->id]);
                }
            } elseif ($user->role === 'DAO_TAO') {
                if (!$user->trainingStaff) {
                    TrainingStaff::firstOrCreate(['user_id' => $user->id]);
                }
            } elseif ($user->role === 'GIANG_VIEN') {
                if (!$user->lecturer) {
                    Lecturer::firstOrCreate(['user_id' => $user->id]);
                }
            }
        } catch (\Throwable $e) {
            Log::warning('ensureRoleModels warning: '.$e->getMessage());
        }
    }
}

