<?php

/**
 * Script test API schedule để kiểm tra:
 * 1. API có trả về đủ semesters không
 * 2. API có filter đúng schedules theo semester không
 * 3. Logic tự động chọn semester có assignment có hoạt động không
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Lecturer;
use App\Models\Semester;
use App\Models\Assignment;
use App\Models\Schedule;
use Illuminate\Support\Facades\DB;

echo "=== TEST API SCHEDULE ===\n\n";

// Lấy lecturer đầu tiên để test
$lecturer = Lecturer::first();
if (!$lecturer) {
    echo "❌ Không tìm thấy lecturer nào để test\n";
    exit(1);
}

echo "📋 Lecturer ID: {$lecturer->id}\n";
echo "📋 Lecturer Name: {$lecturer->name ?? 'N/A'}\n\n";

// 1. Kiểm tra tất cả semesters trong hệ thống
echo "1. KIỂM TRA TẤT CẢ SEMESTERS:\n";
$allSemesters = Semester::orderBy('start_date', 'desc')->get();
echo "   Tổng số semesters: {$allSemesters->count()}\n";
foreach ($allSemesters as $semester) {
    echo "   - ID: {$semester->id}, Code: {$semester->code}, Name: {$semester->name}\n";
}
echo "\n";

// 2. Kiểm tra semesters mà lecturer có assignment
echo "2. KIỂM TRA SEMESTERS MÀ LECTURER CÓ ASSIGNMENT:\n";
$lecturerSemesterIds = Assignment::query()
    ->select('semester_id')
    ->where('lecturer_id', $lecturer->id)
    ->whereNotNull('semester_id')
    ->distinct()
    ->pluck('semester_id')
    ->toArray();

echo "   Số lượng semesters có assignment: " . count($lecturerSemesterIds) . "\n";
foreach ($lecturerSemesterIds as $semesterId) {
    $semester = Semester::find($semesterId);
    if ($semester) {
        echo "   - ID: {$semester->id}, Code: {$semester->code}, Name: {$semester->name}\n";
    }
}
echo "\n";

// 3. Kiểm tra số lượng schedules theo từng semester
echo "3. KIỂM TRA SỐ LƯỢNG SCHEDULES THEO TỪNG SEMESTER:\n";
foreach ($allSemesters as $semester) {
    $scheduleCount = Schedule::query()
        ->whereHas('assignment', function ($query) use ($lecturer, $semester) {
            $query->where('lecturer_id', $lecturer->id)
                  ->where('semester_id', $semester->id);
        })
        ->count();
    
    $hasAssignment = in_array($semester->id, $lecturerSemesterIds);
    $status = $hasAssignment ? "✅ Có assignment" : "❌ Không có assignment";
    echo "   - Semester {$semester->code} ({$semester->name}): {$scheduleCount} schedules - {$status}\n";
}
echo "\n";

// 4. Test logic tự động chọn semester
echo "4. TEST LOGIC TỰ ĐỘNG CHỌN SEMESTER:\n";
$semesterOptions = $allSemesters->map(fn($semester) => [
    'value' => (string) $semester->id,
    'label' => $semester->name,
    'code' => $semester->code,
]);

$semesterFilter = null; // Giả lập không có semesterFilter từ request
if (!$semesterFilter) {
    // Tìm semester đầu tiên trong danh sách mà lecturer có assignment
    foreach ($semesterOptions as $semester) {
        if (in_array((int)$semester['value'], $lecturerSemesterIds)) {
            $semesterFilter = $semester['value'];
            echo "   ✅ Tự động chọn: {$semester['code']} ({$semester['label']})\n";
            break;
        }
    }
}

if (!$semesterFilter) {
    echo "   ❌ Không tìm thấy semester nào có assignment\n";
} else {
    $selectedSemester = Semester::find($semesterFilter);
    $scheduleCount = Schedule::query()
        ->whereHas('assignment', function ($query) use ($lecturer, $semesterFilter) {
            $query->where('lecturer_id', $lecturer->id)
                  ->where('semester_id', $semesterFilter);
        })
        ->count();
    echo "   📊 Số lượng schedules: {$scheduleCount}\n";
}
echo "\n";

echo "=== KẾT THÚC TEST ===\n";

