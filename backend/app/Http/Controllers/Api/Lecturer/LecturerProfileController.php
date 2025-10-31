<?php

namespace App\Http\Controllers\API\Lecturer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lecturer\PasswordChangeRequest;
use App\Http\Requests\Lecturer\ProfileUpdateRequest;
use App\Http\Resources\Lecturer\LecturerProfileResource;
use App\Models\Department;
use App\Models\Faculty;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use OpenApi\Annotations as OA;

class LecturerProfileController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/me/profile",
     *   operationId="lecturerProfileShow",
     *   tags={"Lecturer - Hồ sơ"},
     *   summary="Lấy thông tin hồ sơ giảng viên",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Thông tin hồ sơ",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/LecturerProfile")
     *     )
     *   ),
     *   @OA\Response(
     *     response=401,
     *     description="Chưa xác thực",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function show(Request $request)
    {
        $user = $request->user()->load(['lecturer.department.faculty']);

        return response()->json([
            'data' => new LecturerProfileResource($user),
        ]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/me/profile",
     *   operationId="lecturerProfileUpdate",
     *   tags={"Lecturer - Hồ sơ"},
     *   summary="Cập nhật hồ sơ giảng viên",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="name", type="string", example="Nguyễn Văn A"),
     *       @OA\Property(property="email", type="string", format="email", example="giangvien@qlgd.test"),
     *       @OA\Property(property="phone", type="string", example="0901123456"),
     *       @OA\Property(property="date_of_birth", type="string", format="date", example="1990-05-12"),
     *       @OA\Property(property="gender", type="string", example="Nam"),
     *       @OA\Property(property="department_id", type="integer", nullable=true, example=15),
     *       @OA\Property(property="faculty_id", type="integer", nullable=true, example=3)
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Cập nhật thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", ref="#/components/schemas/LecturerProfile")
     *     )
     *   ),
     *   @OA\Response(
     *     response=404,
     *     description="Không tìm thấy hồ sơ giảng viên",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function update(ProfileUpdateRequest $request)
    {
        $user = $request->user();
        $lecturer = $user->lecturer;

        if (!$lecturer) {
            return response()->json(['message' => 'Không tìm thấy hồ sơ giảng viên'], 404);
        }

        $data = $request->validated();

        $userPayload = [];
        foreach (['name', 'email', 'phone'] as $field) {
            if (array_key_exists($field, $data)) {
                $userPayload[$field] = $data[$field];
            }
        }

        $lecturerPayload = [];
        if (array_key_exists('date_of_birth', $data)) {
            $lecturerPayload['date_of_birth'] = $data['date_of_birth'];
        }
        if (array_key_exists('gender', $data)) {
            $lecturerPayload['gender'] = $data['gender'];
        }

        $department = null;
        if (array_key_exists('department_id', $data)) {
            $department = $data['department_id']
                ? Department::with('faculty')->find($data['department_id'])
                : null;
            $lecturerPayload['department_id'] = $department?->id;

            if (!$department) {
                $lecturerPayload['department_name'] = null;
                if (!array_key_exists('faculty', $data) && !array_key_exists('faculty_id', $data)) {
                    $lecturerPayload['faculty_name'] = null;
                }
            }
        }

        if ($department) {
            $lecturerPayload['department_name'] = $department->name;
            $lecturerPayload['faculty_name'] = $department->faculty?->name;
        }

        if (!$department && array_key_exists('department', $data)) {
            $lecturerPayload['department_name'] = $data['department'] ?: null;
        }

        if (array_key_exists('faculty', $data)) {
            $lecturerPayload['faculty_name'] = $data['faculty'] ?: null;
        } elseif (array_key_exists('faculty_id', $data) && !$department) {
            $faculty = $data['faculty_id'] ? Faculty::find($data['faculty_id']) : null;
            $lecturerPayload['faculty_name'] = $faculty?->name;
        }

        if (array_key_exists('department_id', $data) && !$department && !array_key_exists('department', $data)) {
            $lecturerPayload['department_name'] = $lecturerPayload['department_name'] ?? null;
        }

        if (!empty($userPayload)) {
            $user->fill($userPayload)->save();
        }

        if (!empty($lecturerPayload)) {
            $lecturer->fill($lecturerPayload)->save();
        }

        $user->load(['lecturer.department.faculty']);

        return response()->json([
            'data' => new LecturerProfileResource($user),
        ]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/me/change-password",
     *   operationId="lecturerChangePassword",
     *   tags={"Lecturer - Hồ sơ"},
     *   summary="Đổi mật khẩu đăng nhập",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"current_password","password","password_confirmation"},
     *       @OA\Property(property="current_password", type="string", format="password", example="oldSecret"),
     *       @OA\Property(property="password", type="string", format="password", example="newSecret123"),
     *       @OA\Property(property="password_confirmation", type="string", format="password", example="newSecret123")
     *     )
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Đổi mật khẩu thành công",
     *     @OA\JsonContent(
     *       @OA\Property(property="message", type="string", example="Đổi mật khẩu thành công.")
     *     )
     *   ),
     *   @OA\Response(
     *     response=422,
     *     description="Không hợp lệ",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function changePassword(PasswordChangeRequest $request)
    {
        $data = $request->validated();

        $user = $request->user();
        $user->forceFill([
            'password' => Hash::make($data['password']),
        ])->save();

        return response()->json([
            'message' => 'Đổi mật khẩu thành công.',
        ]);
    }
}
