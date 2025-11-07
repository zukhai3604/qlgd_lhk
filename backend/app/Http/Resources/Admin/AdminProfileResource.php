<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Resources\Json\JsonResource;

class AdminProfileResource extends JsonResource
{
    public function toArray($request)
    {
        $user = $this->resource; // App\Models\User
        $admin = $user->admin;

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'avatar_url' => $user->avatar_url ?? null,

            'admin' => $admin ? [
                'id' => $admin->id,
                'gender' => $admin->gender,
                'date_of_birth' => optional($admin->date_of_birth)->format('Y-m-d'),
                'avatar_url' => $admin->avatar_url,
            ] : null,
        ];
    }
}

