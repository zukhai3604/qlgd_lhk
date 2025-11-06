<?php
// Script để kiểm tra và fix database
// Chạy: php artisan tinker < check_and_fix.php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

echo "=== KIỂM TRA DATABASE ===\n\n";

// 1. Kiểm tra migrations đã chạy
echo "1. Migrations đã chạy:\n";
$migrations = DB::table('migrations')->where('migration', 'like', '%semester%')->get();
foreach ($migrations as $m) {
    echo "   - {$m->migration}\n";
}

echo "\n";

// 2. Kiểm tra bảng semesters
echo "2. Bảng semesters:\n";
if (Schema::hasTable('semesters')) {
    $hasIsActive = Schema::hasColumn('semesters', 'is_active');
    echo "   - Tồn tại: YES\n";
    echo "   - Có cột is_active: " . ($hasIsActive ? "YES (cần xóa)" : "NO (OK)") . "\n";
    
    $count = DB::table('semesters')->count();
    echo "   - Số lượng: $count\n";
    
    if ($count > 0) {
        $semesters = DB::table('semesters')->select('id', 'code', 'name')->get();
        foreach ($semesters as $s) {
            echo "     * {$s->code}: {$s->name}\n";
        }
    } else {
        echo "   - RỖNG! Cần seed data\n";
    }
} else {
    echo "   - Tồn tại: NO\n";
}

echo "\n";

// 3. Kiểm tra bảng assignments
echo "3. Bảng assignments:\n";
if (Schema::hasTable('assignments')) {
    $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
    $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
    
    echo "   - Có semester_id: " . ($hasSemesterId ? "YES" : "NO") . "\n";
    echo "   - Có semester_label: " . ($hasSemesterLabel ? "YES" : "NO") . "\n";
    
    if ($hasSemesterId) {
        $nullCount = DB::table('assignments')->whereNull('semester_id')->count();
        $totalCount = DB::table('assignments')->count();
        echo "   - Assignments có semester_id: " . ($totalCount - $nullCount) . "/$totalCount\n";
    }
}

echo "\n=== KẾT LUẬN ===\n";
echo "Nếu semesters rỗng, chạy: php artisan db:seed --class=SemesterSeeder\n";
echo "Nếu còn is_active, cần xóa thủ công hoặc rollback migration\n";

