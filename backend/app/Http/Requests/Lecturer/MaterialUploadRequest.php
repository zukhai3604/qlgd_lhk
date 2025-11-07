<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class MaterialUploadRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'GIANG_VIEN';
    }

    public function rules(): array
    {
        return [
            'title' => ['required','string','max:180'],
            'file'  => ['required','file','max:10240'], // 10MB
        ];
    }
}
