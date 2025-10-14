<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule; // <-- Quan trọng: Cần để kiểm tra email duy nhất

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Giả định Admin luôn có quyền, chúng ta sẽ làm chặt chẽ hơn sau với Policies
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        // Lấy ID của user đang được cập nhật từ URL
        $userId = $this->route('user')->id;

        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                // Kiểm tra email là duy nhất, NHƯNG bỏ qua (ignore) chính user này
                Rule::unique('users')->ignore($userId),
            ],
            'role' => ['required', 'string', 'in:admin,training_department,lecturer'],
            'phone' => ['nullable', 'string', 'max:20'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}