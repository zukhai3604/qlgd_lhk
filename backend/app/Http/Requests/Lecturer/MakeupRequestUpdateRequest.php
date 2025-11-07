<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class MakeupRequestUpdateRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'suggested_date' => ['sometimes','date'],
            'timeslot_id' => ['sometimes','integer','exists:timeslots,id'],
            'room_id' => ['nullable','integer','exists:rooms,id'],
            'note' => ['nullable','string','max:255'],
        ];
    }
}

