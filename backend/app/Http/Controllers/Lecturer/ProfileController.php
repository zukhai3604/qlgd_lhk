<?php

namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        // Lấy user đang đăng nhập + eager-load các quan hệ cần thiết
        $user = $request->user()->loadMissing([
            'lecturer.department.faculty',
        ]);

        $lecturer = $user->lecturer;

     return response()->json([
         'user' => [
             'id'    => $user->id,
             'name'  => $user->name,
             'email' => $user->email,
             'phone' => $user->phone,
             'role'  => $user->role,
         ],
         'lecturer' => [
             'gender'        => $lecturer->gender ?? null,
             'date_of_birth' => $lecturer->date_of_birth ?? null,
             'department'    => $lecturer?->department ? [
                 'id'   => $lecturer->department->id,
                 'name' => $lecturer->department->name,
                 'faculty' => $lecturer->department->faculty ? [
                     'id'   => $lecturer->department->faculty->id,
                     'name' => $lecturer->department->faculty->name,
                 ] : null,
             ] : null,
         ],
         'avatar_url' => $lecturer->avatar_url ?? null,
     ]);

    }
}
