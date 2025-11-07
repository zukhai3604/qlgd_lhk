<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\AdminProfileUpdateRequest;
use App\Http\Resources\Admin\AdminProfileResource;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user()->load(['admin']);
        return response()->json([
            'data' => new AdminProfileResource($user),
        ]);
    }

    public function update(AdminProfileUpdateRequest $request)
    {
        $user = $request->user();
        $admin = $user->admin;

        if (!$admin) {
            return response()->json(['message' => 'Không tìm thấy hồ sơ admin'], 404);
        }

        $data = $request->validated();

        $userPayload = [];
        foreach (['name','email','phone'] as $f) {
            if (array_key_exists($f, $data)) {
                $userPayload[$f] = $data[$f];
            }
        }

        $adminPayload = [];
        foreach (['date_of_birth','gender'] as $f) {
            if (array_key_exists($f, $data)) {
                $adminPayload[$f] = $data[$f];
            }
        }

        if (!empty($userPayload)) {
            $user->fill($userPayload)->save();
        }
        if (!empty($adminPayload)) {
            $admin->fill($adminPayload)->save();
        }

        $user->load(['admin']);

        return response()->json([
            'data' => new AdminProfileResource($user),
        ]);
    }
}

