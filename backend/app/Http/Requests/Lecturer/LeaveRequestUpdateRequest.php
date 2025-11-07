<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class LeaveRequestUpdateRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'reason' => ['sometimes','string','max:255'],
            'note' => ['nullable','string','max:255'],
        ];
    }
}

