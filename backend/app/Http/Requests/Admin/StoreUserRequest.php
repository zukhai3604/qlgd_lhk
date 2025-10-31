<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Admin tạo user mới
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')],
            'password' => ['required', 'string', 'min:6'],
            // Canonical roles consistent with DB enum
            'role' => ['required', 'string', 'in:ADMIN,DAO_TAO,GIANG_VIEN'],
            'is_active' => ['sometimes', 'boolean'],
            'phone' => ['nullable', 'string', 'max:20'],
        ];
    }
}

