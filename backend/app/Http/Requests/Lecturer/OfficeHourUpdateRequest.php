<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class OfficeHourUpdateRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'weekday' => ['sometimes','integer','between:0,6'],
            'start_time' => ['sometimes','date_format:H:i'],
            'end_time' => ['sometimes','date_format:H:i','after:start_time'],
            'location' => ['nullable','string','max:120'],
            'repeat_rule' => ['nullable','string','max:120'],
            'note' => ['nullable','string','max:255'],
        ];
    }
}

