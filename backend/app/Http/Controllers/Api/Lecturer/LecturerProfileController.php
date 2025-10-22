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

class LecturerProfileController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/me/profile",
     *   tags={"Lecturer"},
     *   summary="Hồ sơ giảng viên",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK")
     * )
     */
    public function show(Request $request)
    {
        $user = $request->user()->load(['lecturer.department.faculty']);
        return response()->json(['data' => new LecturerProfileResource($user)]);
    }

    /**
     * @OA\Patch(
     *   path="/api/lecturer/me/profile",
     *   tags={"Lecturer"},
     *   summary="Cập nhật hồ sơ",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=404, description="Not Found")
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
        $lecturerPayload = [];

        foreach (['name', 'email', 'phone', 'date_of_birth', 'gender'] as $field) {
            if (array_key_exists($field, $data)) {
                $userPayload[$field] = $data[$field];
            }
        }

        if (!empty($data['date_of_birth'])) {
            $lecturerPayload['date_of_birth'] = $data['date_of_birth'];
        }

        if (!empty($data['gender'])) {
            $lecturerPayload['gender'] = $data['gender'];
        }

        $department = null;
        if (array_key_exists('department_id', $data)) {
            $department = $data['department_id']
                ? Department::with('faculty')->find($data['department_id'])
                : null;
            $lecturerPayload['department_id'] = $department?->id;
        }

        if ($department) {
            $userPayload['department'] = $department->name;
            $userPayload['faculty'] = $department->faculty?->name;
        }

        if (!$department && array_key_exists('department', $data)) {
            $userPayload['department'] = $data['department'];
        }

        if (array_key_exists('faculty', $data)) {
            $userPayload['faculty'] = $data['faculty'];
        } elseif (array_key_exists('faculty_id', $data) && !$department) {
            $faculty = $data['faculty_id'] ? Faculty::find($data['faculty_id']) : null;
            $userPayload['faculty'] = $faculty?->name;
        }

        if (!empty($userPayload)) {
            $user->fill($userPayload)->save();
        }

        if (!empty($lecturerPayload)) {
            $lecturer->fill($lecturerPayload)->save();
        }

        $user->load(['lecturer.department.faculty']);

        return response()->json(['data' => new LecturerProfileResource($user)]);
    }

    /**
     * @OA\Post(
     *   path="/api/lecturer/me/change-password",
     *   tags={"Lecturer"},
     *   summary="Đổi mật khẩu",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"current_password","password","password_confirmation"},
     *       @OA\Property(property="current_password", type="string", format="password"),
     *       @OA\Property(property="password", type="string", format="password"),
     *       @OA\Property(property="password_confirmation", type="string", format="password")
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=422, description="Validation Error")
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
