<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule; 

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Admin luôn có quyền cập nhật user khác
        return true; 
    }

    public function rules(): array
    {
        // Lấy ID của user đang được cập nhật thông qua Route Model Binding
        $userId = $this->route('user')->id; 
        
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required', 
                'email', 
                'max:255', 
                // QUAN TRỌNG: Kiểm tra tính duy nhất của email, nhưng bỏ qua ID của user hiện tại
                Rule::unique('users', 'email')->ignore($userId), 
            ],
            // Password không được gửi lên đây; nếu gửi, nó sẽ được xử lý bởi hàm resetPassword riêng
            'role' => ['required', 'string', 'in:admin,training_department,lecturer'],
            'is_active' => ['sometimes', 'boolean'], // Chỉ cập nhật nếu có gửi lên
            'phone' => ['nullable', 'string', 'max:20'],
        ];
    }
}