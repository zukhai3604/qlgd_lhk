<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class AdminProfileUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes','string','max:255'],
            'email' => ['sometimes','email','max:255'],
            'phone' => ['sometimes','string','max:30'],

            'date_of_birth' => ['sometimes','date'],
            'gender' => ['sometimes','in:Nam,Nữ,Khác','nullable'],
        ];
    }
}

