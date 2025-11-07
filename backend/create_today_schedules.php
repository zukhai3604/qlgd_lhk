<?php

/**
 * Script tạo nhiều buổi học hôm nay để test
 * Chạy: docker-compose exec workspace php create_today_schedules.php
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Schedule;
use App\Models\Assignment;
use App\Models\Timeslot;
use App\Models\Room;
use Carbon\Carbon;

$today = Carbon::today()->toDateString();
echo "=== Tạo buổi học cho ngày: $today ===\n\n";

// Lấy lecturer ID từ user hiện tại (hoặc hardcode nếu cần)
// Giả sử bạn đang login với lecturer_id = 6 (dựa trên marked_by trong attendance)
$lecturerId = 6; // Thay đổi theo lecturer ID của bạn

// Lấy assignments của lecturer
$assignments = Assignment::where('lecturer_id', $lecturerId)
    ->with(['subject', 'classUnit'])
    ->get();

if ($assignments->isEmpty()) {
    echo "❌ Không tìm thấy assignment nào cho lecturer ID: $lecturerId\n";
    echo "Hãy kiểm tra lại lecturer_id hoặc tạo assignment trước.\n";
    exit(1);
}

echo "📚 Tìm thấy " . $assignments->count() . " assignment(s)\n\n";

// Lấy timeslots theo ngày hôm nay
$dayOfWeek = Carbon::today()->dayOfWeek; // 0=CN, 1=T2, ..., 6=T7
$timeslotDay = $dayOfWeek === 0 ? 7 : $dayOfWeek; // Convert: CN=7

$timeslots = Timeslot::where('day_of_week', $timeslotDay)
    ->orderBy('start_time')
    ->limit(12)
    ->get();

if ($timeslots->isEmpty()) {
    // Fallback: lấy các timeslot T2 nếu không có timeslot cho ngày hôm nay
    $timeslots = Timeslot::where('day_of_week', 2)
        ->orderBy('start_time')
        ->limit(12)
        ->get();
}

if ($timeslots->isEmpty()) {
    echo "❌ Không tìm thấy timeslot nào\n";
    exit(1);
}

echo "⏰ Tìm thấy " . $timeslots->count() . " timeslot(s) cho ngày hôm nay\n\n";

// Lấy rooms
$rooms = Room::orderBy('code')->get();
if ($rooms->isEmpty()) {
    echo "❌ Không tìm thấy room nào\n";
    exit(1);
}

echo "🏫 Tìm thấy " . $rooms->count() . " room(s)\n\n";

// Các status để test
$statuses = ['PLANNED', 'TEACHING', 'DONE', 'CANCELED'];
$roomIndex = 0;
$created = 0;
$skipped = 0;

// Tạo schedules - mỗi assignment tạo 2-3 buổi học
foreach ($assignments as $index => $assignment) {
    // Mỗi assignment tạo 2 buổi học với các status khác nhau
    $timeslotsToUse = $timeslots->slice($index * 2, 2)->all();
    
    if (empty($timeslotsToUse)) {
        break; // Hết timeslot
    }
    
    foreach ($timeslotsToUse as $timeslotIndex => $timeslot) {
        $status = $statuses[$index % count($statuses)];
        $room = $rooms[$roomIndex % $rooms->count()];
        $roomIndex++;
        
        // Kiểm tra xem đã tồn tại chưa
        $exists = Schedule::where('assignment_id', $assignment->id)
            ->where('session_date', $today)
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
                'session_date' => $today,
                'timeslot_id' => $timeslot->id,
                'room_id' => $room->id,
                'status' => $status,
                'note' => null,
                'makeup_of_id' => null,
            ]);
            
            $created++;
            echo "✅ Đã tạo: {$assignment->subject->name} - {$assignment->classUnit->code} - {$timeslot->code} - Status: $status\n";
        } catch (\Exception $e) {
            echo "❌ Lỗi khi tạo: {$e->getMessage()}\n";
        }
    }
}

echo "\n=== Kết quả ===\n";
echo "✅ Đã tạo: $created buổi học\n";
echo "⏭️  Đã bỏ qua: $skipped buổi học (đã tồn tại)\n";
echo "\nHoàn thành!\n";

