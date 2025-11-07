<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use App\Models\Lecturer;
use App\Models\Assignment;
use App\Models\Schedule;
use Carbon\Carbon;

echo "=== Kiểm tra schedules của thái sơn - ngày 07/11/2025 ===\n\n";

// Tìm lecturer "thái sơn"
$user = User::where('role', 'GIANG_VIEN')
    ->whereRaw('LOWER(name) LIKE ?', ['%thái sơn%'])
    ->first();

if (!$user) {
    echo "❌ Không tìm thấy lecturer 'thái sơn'\n";
    exit(1);
}

$lecturer = $user->lecturer;
if (!$lecturer) {
    echo "❌ User không có lecturer profile\n";
    exit(1);
}

echo "✅ Lecturer: {$user->name} (Lecturer ID: {$lecturer->id})\n\n";

// Ngày đích: 07/11/2025
$targetDate = '2025-11-07';

// Đếm schedules
$schedules = Schedule::whereHas('assignment', function($q) use ($lecturer) {
        $q->where('lecturer_id', $lecturer->id);
    })
    ->where('session_date', $targetDate)
    ->with(['assignment.subject', 'assignment.classUnit', 'timeslot', 'room'])
    ->orderBy('timeslot_id')
    ->get();

echo "📊 Tổng số schedules: " . $schedules->count() . "\n\n";

if ($schedules->isEmpty()) {
    echo "⚠️  Chưa có schedules nào cho ngày này\n";
    exit(0);
}

// Nhóm theo status
$byStatus = $schedules->groupBy('status');
echo "📈 Phân bổ theo status:\n";
foreach ($byStatus as $status => $items) {
    echo "  - $status: {$items->count()} buổi\n";
}
echo "\n";

// Hiển thị chi tiết
echo "📋 Chi tiết các buổi học:\n";
echo str_repeat("=", 100) . "\n";
printf("%-5s | %-30s | %-15s | %-12s | %-10s | %-8s\n", 
    "ID", "Môn học", "Lớp", "Timeslot", "Room", "Status");
echo str_repeat("-", 100) . "\n";

foreach ($schedules as $schedule) {
    $subject = $schedule->assignment->subject->name ?? 'N/A';
    $class = $schedule->assignment->classUnit->code ?? 'N/A';
    $timeslot = $schedule->timeslot->code ?? 'N/A';
    $room = $schedule->room->code ?? 'N/A';
    $status = $schedule->status;
    
    printf("%-5s | %-30s | %-15s | %-12s | %-10s | %-8s\n",
        $schedule->id,
        substr($subject, 0, 30),
        substr($class, 0, 15),
        $timeslot,
        $room,
        $status
    );
}

echo str_repeat("=", 100) . "\n";
echo "\n✅ Hoàn thành kiểm tra!\n";

