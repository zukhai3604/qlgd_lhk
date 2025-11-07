<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class LecturerProfileResource extends JsonResource
{
    public function toArray($request)
    {
        $user = $this->resource;
        $lecturer = $user->lecturer;
        $departmentRelation = $lecturer?->department;
        $facultyRelation = $departmentRelation?->faculty;

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'date_of_birth' => optional($lecturer?->date_of_birth)->format('Y-m-d'),
            'gender' => $lecturer?->gender,
            'department' => $departmentRelation?->name ?? $lecturer?->department_name,
            'faculty' => $facultyRelation?->name ?? $lecturer?->faculty_name,
            'role' => $user->role,
            'avatar_url' => $user->avatar_url ?? null,
            'lecturer' => $lecturer ? [
                'id' => $lecturer->id,
                'gender' => $lecturer->gender,
                'date_of_birth' => optional($lecturer->date_of_birth)->format('Y-m-d'),
                'department_id' => $lecturer->department_id,
                'department_name' => $lecturer->department_name,
                'faculty_name' => $lecturer->faculty_name,
                'department' => $departmentRelation ? [
                    'id' => $departmentRelation->id,
                    'code' => $departmentRelation->code,
                    'name' => $departmentRelation->name,
                    'faculty' => $facultyRelation ? [
                        'id' => $facultyRelation->id,
                        'code' => $facultyRelation->code,
                        'name' => $facultyRelation->name,
                    ] : null,
                ] : null,
            ] : null,
        ];
    }
}
