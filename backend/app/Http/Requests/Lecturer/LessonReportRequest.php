<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class LessonReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'GIANG_VIEN';
    }

    public function rules(): array
    {
        return [
            'content'   => ['required','string','max:5000'],
            'issues'    => ['nullable','string','max:5000'],
            'next_plan' => ['nullable','string','max:5000'],
        ];
    }
}
