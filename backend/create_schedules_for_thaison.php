<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use App\Models\Lecturer;
use App\Models\Assignment;
use App\Models\Schedule;
use App\Models\Timeslot;
use App\Models\Room;
use Carbon\Carbon;

echo "=== Tạo buổi học cho thái sơn - ngày 07/11/2025 ===\n\n";

// Tìm lecturer "thái sơn"
$user = User::where('role', 'GIANG_VIEN')
    ->whereRaw('LOWER(name) LIKE ?', ['%thái sơn%'])
    ->first();

if (!$user) {
    echo "❌ Không tìm thấy lecturer 'thái sơn'\n";
    echo "Danh sách lecturers:\n";
    $allLecturers = User::where('role', 'GIANG_VIEN')->get(['id', 'name', 'email']);
    foreach ($allLecturers as $l) {
        echo "  - ID: {$l->id}, Name: {$l->name}, Email: {$l->email}\n";
    }
    exit(1);
}

$lecturer = $user->lecturer;
if (!$lecturer) {
    echo "❌ User không có lecturer profile\n";
    exit(1);
}

echo "✅ Tìm thấy: {$user->name} (Lecturer ID: {$lecturer->id})\n\n";

// Ngày đích: 07/11/2025
$targetDate = '2025-11-07';
$targetDateObj = Carbon::parse($targetDate);
$targetDateStr = $targetDateObj->toDateString();

echo "📅 Ngày: $targetDateStr\n";
echo "📅 Thứ: " . $targetDateObj->format('l') . " (dayOfWeek: {$targetDateObj->dayOfWeek})\n\n";

// Lấy assignments
$assignments = Assignment::where('lecturer_id', $lecturer->id)
    ->with(['subject', 'classUnit'])
    ->get();

if ($assignments->isEmpty()) {
    echo "❌ Không tìm thấy assignment nào\n";
    exit(1);
}

echo "📚 Tìm thấy " . $assignments->count() . " assignment(s):\n";
foreach ($assignments as $a) {
    echo "  - {$a->subject->name} - {$a->classUnit->code}\n";
}
echo "\n";

// Lấy timeslots
$dayOfWeek = $targetDateObj->dayOfWeek; // 0=CN, 1=T2, ..., 6=T7
$timeslotDay = $dayOfWeek === 0 ? 7 : $dayOfWeek;

echo "🔍 Tìm timeslots cho day_of_week: $timeslotDay\n";
$timeslots = Timeslot::where('day_of_week', $timeslotDay)
    ->orderBy('start_time')
    ->get();

if ($timeslots->isEmpty()) {
    echo "⚠️  Không có timeslot cho ngày này, lấy tất cả timeslots\n";
    $timeslots = Timeslot::orderBy('day_of_week')->orderBy('start_time')->limit(20)->get();
}

echo "⏰ Tìm thấy " . $timeslots->count() . " timeslot(s)\n\n";

// Lấy rooms
$rooms = Room::orderBy('code')->get();
echo "🏫 Tìm thấy " . $rooms->count() . " room(s)\n\n";

// Tạo schedules
$targetCount = 15;
$statuses = ['PLANNED', 'TEACHING', 'DONE', 'CANCELED'];
$roomIndex = 0;
$created = 0;
$skipped = 0;
$timeslotIndex = 0;

echo "🚀 Bắt đầu tạo schedules...\n\n";

while ($created < $targetCount && $timeslotIndex < $timeslots->count() * 2) {
    $assignment = $assignments[$created % $assignments->count()];
    $timeslot = $timeslots[$timeslotIndex % $timeslots->count()];
    $timeslotIndex++;
    
    $status = $statuses[$created % count($statuses)];
    $room = $rooms[$roomIndex % $rooms->count()];
    $roomIndex++;
    
    // Kiểm tra tồn tại
    $exists = Schedule::where('assignment_id', $assignment->id)
        ->where('session_date', $targetDateStr)
        ->where('timeslot_id', $timeslot->id)
        ->exists();
    
    if ($exists) {
        echo "⏭️  Đã tồn tại: {$assignment->subject->name} - {$assignment->classUnit->code} - {$timeslot->code}\n";
        $skipped++;
        continue;
    }
    
    try {
        Schedule::create([
            'assignment_id' => $assignment->id,
            'session_date' => $targetDateStr,
            'timeslot_id' => $timeslot->id,
            'room_id' => $room->id,
            'status' => $status,
            'note' => null,
            'makeup_of_id' => null,
        ]);
        
        $created++;
        echo "✅ [$created/$targetCount] {$assignment->subject->name} - {$assignment->classUnit->code} - {$timeslot->code} - Status: $status\n";
    } catch (\Exception $e) {
        echo "❌ Lỗi: {$e->getMessage()}\n";
        continue;
    }
}

echo "\n=== Kết quả ===\n";
echo "✅ Đã tạo: $created buổi học\n";
echo "⏭️  Đã bỏ qua: $skipped buổi học (đã tồn tại)\n";
echo "\nHoàn thành!\n";

