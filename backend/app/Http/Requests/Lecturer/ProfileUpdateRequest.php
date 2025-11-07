<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProfileUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->user()?->id;

        return [
            'name' => ['sometimes', 'string', 'max:150'],
            'email' => [
                'sometimes',
                'email',
                'max:190',
                Rule::unique('users')->ignore($userId),
            ],
            'phone' => ['nullable', 'string', 'max:30'],
            'date_of_birth' => ['nullable', 'date_format:Y-m-d'],
            'gender' => ['nullable', 'in:Nam,Nữ,Khác'],
            'faculty_id' => ['nullable', 'exists:faculties,id'],
            'department_id' => ['nullable', 'exists:departments,id'],
            'department' => ['nullable', 'string', 'max:100'],
            'faculty' => ['nullable', 'string', 'max:100'],
        ];
    }
}
