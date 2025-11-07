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
            'status'    => ['nullable', 'string', function ($attribute, $value, $fail) {
                if ($value !== null) {
                    $upperValue = strtoupper($value);
                    $validStatuses = ['PLANNED', 'TEACHING', 'DONE', 'CANCELED'];
                    if (!in_array($upperValue, $validStatuses)) {
                        $fail("Trạng thái không hợp lệ: $value");
                    }
                }
            }],
            'note'      => ['nullable', 'string', 'max:10000'], // Sau khi mở rộng thành TEXT
            'content'   => ['nullable', 'string', 'max:5000'],
            'issues'    => ['nullable', 'string', 'max:5000'],
            'next_plan' => ['nullable', 'string', 'max:5000'],
        ];
    }
    
    protected function prepareForValidation()
    {
        // Convert status to uppercase before validation
        if ($this->has('status') && $this->status !== null) {
            $this->merge([
                'status' => strtoupper($this->status),
            ]);
        }
    }
}

