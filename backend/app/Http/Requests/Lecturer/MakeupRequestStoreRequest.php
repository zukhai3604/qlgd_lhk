<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class MakeupRequestStoreRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return [
            'leave_request_id' => ['required','integer','exists:leave_requests,id'],
            'suggested_date' => ['required','date'],
            'timeslot_id' => ['required','integer','exists:timeslots,id'],
            'room_id' => ['nullable','integer','exists:rooms,id'],
            'note' => ['nullable','string','max:255'],
        ];
    }
}

