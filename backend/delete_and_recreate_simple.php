<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Schedule;
use Carbon\Carbon;

$today = Carbon::today()->toDateString();
echo "=== Xóa và tạo lại schedules ===\n";
echo "Ngày hôm nay: $today\n\n";

// Đếm trước khi xóa
$countBefore = Schedule::whereDate('session_date', $today)->count();
echo "📊 Số schedules trước khi xóa: $countBefore\n";

// Xóa tất cả schedules của ngày hôm nay
if ($countBefore > 0) {
    $deleted = Schedule::whereDate('session_date', $today)->delete();
    echo "✅ Đã xóa: $deleted schedules\n\n";
} else {
    echo "⚠️  Không có schedules để xóa\n\n";
}

// Đếm sau khi xóa
$countAfter = Schedule::whereDate('session_date', $today)->count();
echo "📊 Số schedules sau khi xóa: $countAfter\n\n";

// Chạy command tạo lại
echo "🔄 Tạo lại schedules...\n";
$output = [];
$returnCode = 0;
exec('php artisan app:create-today-schedules 2>&1', $output, $returnCode);

if (!empty($output)) {
    foreach ($output as $line) {
        echo $line . "\n";
    }
}

// Đếm sau khi tạo
$countFinal = Schedule::whereDate('session_date', $today)->count();
echo "\n📊 Số schedules sau khi tạo: $countFinal\n";
echo "✅ Hoàn thành!\n";

