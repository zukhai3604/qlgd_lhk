<?php

namespace App\Http\Resources\TrainingDepartment;

use Illuminate\Http\Resources\Json\JsonResource;

class TrainingStaffProfileResource extends JsonResource
{
    public function toArray($request)
    {
        $user = $this->resource; // App\Models\User
        $staff = $user->trainingStaff;

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'avatar_url' => $user->avatar_url ?? null,

            'training_staff' => $staff ? [
                'id' => $staff->id,
                'gender' => $staff->gender,
                'date_of_birth' => optional($staff->date_of_birth)->format('Y-m-d'),
                'position' => $staff->position,
                'avatar_url' => $staff->avatar_url,
            ] : null,
        ];
    }
}

