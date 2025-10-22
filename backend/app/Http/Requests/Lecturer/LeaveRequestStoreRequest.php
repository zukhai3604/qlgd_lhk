<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class LeaveRequestStoreRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'schedule_id' => ['required','integer','exists:schedules,id'],
            'reason' => ['required','string','max:255'],
        ];
    }
}

