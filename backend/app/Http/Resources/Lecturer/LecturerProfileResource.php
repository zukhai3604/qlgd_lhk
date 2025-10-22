<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class LecturerProfileResource extends JsonResource
{
    public function toArray($request)
    {
        $user = $this->resource;
        $lecturer = $user->lecturer;
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'date_of_birth' => optional($user->date_of_birth)->format('Y-m-d'),
            'gender' => $user->gender,
            'department' => $user->department,
            'faculty' => $user->faculty,
            'role' => $user->role,
            'avatar_url' => $user->avatar_url ?? null,
            'lecturer' => $lecturer ? [
                'id' => $lecturer->id,
                'gender' => $lecturer->gender,
                'date_of_birth' => optional($lecturer->date_of_birth)->format('Y-m-d'),
                'department_id' => $lecturer->department_id,
                'department' => $lecturer->department ? [
                    'id' => $lecturer->department->id,
                    'code' => $lecturer->department->code,
                    'name' => $lecturer->department->name,
                    'faculty' => $lecturer->department->faculty ? [
                        'id' => $lecturer->department->faculty->id,
                        'code' => $lecturer->department->faculty->code,
                        'name' => $lecturer->department->faculty->name,
                    ] : null,
                ] : null,
            ] : null,
        ];
    }
}
