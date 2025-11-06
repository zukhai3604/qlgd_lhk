<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Đăng ký scheduled task: Tự động hủy schedules đã qua thời gian
Schedule::command('schedules:cancel-past')
    ->dailyAt('01:00')
    ->description('Tự động hủy các buổi học đã qua thời gian');
