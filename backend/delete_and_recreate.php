<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use App\Models\Schedule;
use Carbon\Carbon;

$today = Carbon::today()->toDateString();
echo "=== Xóa và tạo lại schedules ===\n\n";

// Tìm lecturer "thái sơn"
$user = User::where('role', 'GIANG_VIEN')
    ->whereRaw('LOWER(name) LIKE ?', ['%thái sơn%'])
    ->first();

if (!$user || !$user->lecturer) {
    echo "❌ Không tìm thấy lecturer\n";
    exit(1);
}

echo "✅ Lecturer: {$user->name} (ID: {$user->lecturer->id})\n";

// Đếm và xóa schedules của lecturer này
$countBefore = Schedule::whereHas('assignment', function($q) use ($user) {
    $q->where('lecturer_id', $user->lecturer->id);
})
->whereDate('session_date', $today)
->count();

echo "📊 Schedules trước khi xóa: $countBefore\n";

if ($countBefore > 0) {
    $deleted = Schedule::whereHas('assignment', function($q) use ($user) {
        $q->where('lecturer_id', $user->lecturer->id);
    })
    ->whereDate('session_date', $today)
    ->delete();
    
    echo "✅ Đã xóa: $deleted schedules\n\n";
} else {
    echo "⚠️  Không có schedules để xóa\n\n";
}

// Chạy command tạo lại
echo "🔄 Tạo lại schedules...\n";
exec('php artisan app:create-today-schedules', $output, $returnCode);

foreach ($output as $line) {
    echo $line . "\n";
}

echo "\n✅ Hoàn thành!\n";

