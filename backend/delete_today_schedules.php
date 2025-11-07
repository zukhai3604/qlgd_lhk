<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use App\Models\Schedule;
use Carbon\Carbon;

$today = Carbon::today()->toDateString();
echo "=== Xóa schedules cũ cho ngày hôm nay ($today) ===\n\n";

// Tìm lecturer "thái sơn"
$user = User::where('role', 'GIANG_VIEN')
    ->whereRaw('LOWER(name) LIKE ?', ['%thái sơn%'])
    ->first();

if (!$user || !$user->lecturer) {
    echo "❌ Không tìm thấy lecturer\n";
    exit(1);
}

// Đếm trước khi xóa
$countBefore = Schedule::whereHas('assignment', function($q) use ($user) {
    $q->where('lecturer_id', $user->lecturer->id);
})
->whereDate('session_date', $today)
->count();

echo "📊 Số schedules trước khi xóa: $countBefore\n";

// Xóa schedules
$deleted = Schedule::whereHas('assignment', function($q) use ($user) {
    $q->where('lecturer_id', $user->lecturer->id);
})
->whereDate('session_date', $today)
->delete();

echo "✅ Đã xóa: $deleted schedules\n\n";

// Đếm sau khi xóa
$countAfter = Schedule::whereHas('assignment', function($q) use ($user) {
    $q->where('lecturer_id', $user->lecturer->id);
})
->whereDate('session_date', $today)
->count();

echo "📊 Số schedules sau khi xóa: $countAfter\n";
echo "✅ Hoàn thành!\n";

