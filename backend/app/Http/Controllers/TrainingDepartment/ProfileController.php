<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Http\Requests\TrainingDepartment\ProfileUpdateRequest;
use App\Http\Resources\TrainingDepartment\TrainingStaffProfileResource;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user()->load(['trainingStaff']);
        return response()->json([
            'data' => new TrainingStaffProfileResource($user),
        ]);
    }

    public function update(ProfileUpdateRequest $request)
    {
        $user = $request->user();
        $staff = $user->trainingStaff;

        if (!$staff) {
            return response()->json(['message' => 'Không tìm thấy hồ sơ phòng đào tạo'], 404);
        }

        $data = $request->validated();

        $userPayload = [];
        foreach (['name','email','phone'] as $f) {
            if (array_key_exists($f, $data)) {
                $userPayload[$f] = $data[$f];
            }
        }

        $staffPayload = [];
        foreach (['date_of_birth','gender','position'] as $f) {
            if (array_key_exists($f, $data)) {
                $staffPayload[$f] = $data[$f];
            }
        }

        if (!empty($userPayload)) {
            $user->fill($userPayload)->save();
        }
        if (!empty($staffPayload)) {
            $staff->fill($staffPayload)->save();
        }

        $user->load(['trainingStaff']);

        return response()->json([
            'data' => new TrainingStaffProfileResource($user),
        ]);
    }
}

