<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class SessionUpdateRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'note' => ['nullable','string','max:255'],
            'room_id' => ['nullable','integer','exists:rooms,id'],
        ];
    }
}

