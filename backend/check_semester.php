<?php
// Script để kiểm tra và fix database
// Chạy: php artisan tinker < check_semester.php
// Hoặc copy vào tinker

use App\Models\Semester;
use App\Models\Assignment;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

echo "=== KIỂM TRA DATABASE ===\n\n";

// 1. Kiểm tra bảng semesters
echo "1. Kiểm tra bảng semesters:\n";
if (Schema::hasTable('semesters')) {
    $hasIsActive = Schema::hasColumn('semesters', 'is_active');
    echo "   - Bảng semesters: tồn tại\n";
    echo "   - Cột is_active: " . ($hasIsActive ? "CÓ (cần xóa)" : "KHÔNG (OK)") . "\n";
    
    $semesterCount = DB::table('semesters')->count();
    echo "   - Số lượng semester: $semesterCount\n";
    
    if ($semesterCount > 0) {
        $semesters = DB::table('semesters')->select('id', 'code', 'name')->get();
        echo "   - Danh sách semester:\n";
        foreach ($semesters as $s) {
            echo "     * ID: {$s->id}, Code: {$s->code}, Name: {$s->name}\n";
        }
    }
} else {
    echo "   - Bảng semesters: KHÔNG TỒN TẠI\n";
}

echo "\n";

// 2. Kiểm tra bảng assignments
echo "2. Kiểm tra bảng assignments:\n";
if (Schema::hasTable('assignments')) {
    $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
    $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
    
    echo "   - Bảng assignments: tồn tại\n";
    echo "   - Cột semester_id: " . ($hasSemesterId ? "CÓ (OK)" : "KHÔNG (cần thêm)") . "\n";
    echo "   - Cột semester_label: " . ($hasSemesterLabel ? "CÓ (cần xóa)" : "KHÔNG (OK)") . "\n";
    
    $assignmentCount = DB::table('assignments')->count();
    echo "   - Số lượng assignment: $assignmentCount\n";
    
    if ($hasSemesterId && $assignmentCount > 0) {
        $nullSemesterId = DB::table('assignments')->whereNull('semester_id')->count();
        echo "   - Assignments chưa có semester_id: $nullSemesterId\n";
    }
} else {
    echo "   - Bảng assignments: KHÔNG TỒN TẠI\n";
}

echo "\n=== KẾT LUẬN ===\n";
echo "Nếu có vấn đề, chạy: php artisan migrate\n";

