<?php

namespace App\Http\Requests\Lecturer;

use Illuminate\Foundation\Http\FormRequest;

class ScheduleReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'GIANG_VIEN';
    }

    public function rules(): array
    {
        return [
            'status'    => ['nullable', 'string', 'in:PLANNED,TEACHING,DONE,CANCELED'],
            'note'      => ['nullable', 'string', 'max:10000'], // Sau khi mở rộng thành TEXT
            'content'   => ['nullable', 'string', 'max:5000'],
            'issues'    => ['nullable', 'string', 'max:5000'],
            'next_plan' => ['nullable', 'string', 'max:5000'],
        ];
    }
}

