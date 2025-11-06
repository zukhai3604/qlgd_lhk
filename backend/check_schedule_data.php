<?php

/**
 * Script kiểm tra dữ liệu schedules và semesters
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

echo "=== KIỂM TRA DỮ LIỆU SCHEDULES VÀ SEMESTERS ===\n\n";

// 1. Kiểm tra tất cả semesters
echo "1. TẤT CẢ SEMESTERS:\n";
$allSemesters = Semester::orderBy('start_date', 'desc')->get();
echo "   Tổng số: {$allSemesters->count()}\n";
foreach ($allSemesters as $semester) {
    echo "   - ID: {$semester->id}, Code: {$semester->code}, Name: {$semester->name}\n";
}
echo "\n";

// 2. Kiểm tra lecturers có assignment
echo "2. LECTURERS CÓ ASSIGNMENT:\n";
$lecturersWithAssignments = Lecturer::query()
    ->whereHas('assignments')
    ->get();
echo "   Tổng số: {$lecturersWithAssignments->count()}\n";
foreach ($lecturersWithAssignments->take(5) as $lecturer) {
    $assignmentCount = $lecturer->assignments()->count();
    $scheduleCount = Schedule::query()
        ->whereHas('assignment', function ($query) use ($lecturer) {
            $query->where('lecturer_id', $lecturer->id);
        })
        ->count();
    echo "   - ID: {$lecturer->id}, Name: {$lecturer->name ?? 'N/A'}, Assignments: {$assignmentCount}, Schedules: {$scheduleCount}\n";
}
echo "\n";

// 3. Kiểm tra assignments theo semester
echo "3. ASSIGNMENTS THEO SEMESTER:\n";
foreach ($allSemesters as $semester) {
    $assignmentCount = Assignment::where('semester_id', $semester->id)->count();
    $scheduleCount = Schedule::query()
        ->whereHas('assignment', function ($query) use ($semester) {
            $query->where('semester_id', $semester->id);
        })
        ->count();
    echo "   - {$semester->code}: {$assignmentCount} assignments, {$scheduleCount} schedules\n";
}
echo "\n";

// 4. Kiểm tra schedules tổng thể
echo "4. TỔNG QUAN SCHEDULES:\n";
$totalSchedules = Schedule::count();
echo "   Tổng số schedules: {$totalSchedules}\n";
$schedulesByStatus = Schedule::select('status', DB::raw('count(*) as count'))
    ->groupBy('status')
    ->get();
foreach ($schedulesByStatus as $stat) {
    echo "   - {$stat->status}: {$stat->count}\n";
}
echo "\n";

echo "=== KẾT THÚC ===\n";

