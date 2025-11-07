<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class AttendanceStoreRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'records' => ['required','array','min:1'],
            'records.*.student_id' => ['required','integer','exists:students,id'],
            'records.*.status' => ['required','in:PRESENT,ABSENT,LATE,EXCUSED'],
            'records.*.note' => ['nullable','string','max:255'],
        ];
    }
}

