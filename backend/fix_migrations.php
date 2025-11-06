<?php
// Script để kiểm tra và chạy migrations còn thiếu
// Chạy trong Docker: php artisan tinker < fix_migrations.php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

echo "=== KIỂM TRA VÀ FIX MIGRATIONS ===\n\n";

// 1. Kiểm tra semesters
echo "1. Bảng semesters:\n";
if (Schema::hasTable('semesters')) {
    $hasIsActive = Schema::hasColumn('semesters', 'is_active');
    echo "   - Tồn tại: YES\n";
    echo "   - Có is_active: " . ($hasIsActive ? "YES (cần xóa)" : "NO (OK)") . "\n";
    
    if ($hasIsActive) {
        echo "   → Xóa cột is_active...\n";
        DB::statement('ALTER TABLE semesters DROP COLUMN is_active');
        echo "   ✓ Đã xóa is_active\n";
    }
    
    $count = DB::table('semesters')->count();
    echo "   - Số lượng: $count\n";
    
    if ($count == 0) {
        echo "   → Seed data...\n";
        $semesters = [
            ['code' => '2024-2025 HK1', 'name' => 'Học kỳ I 2024-2025', 'start_date' => '2024-09-01', 'end_date' => '2024-12-31', 'created_at' => now(), 'updated_at' => now()],
            ['code' => '2024-2025 HK2', 'name' => 'Học kỳ II 2024-2025', 'start_date' => '2025-01-15', 'end_date' => '2025-05-31', 'created_at' => now(), 'updated_at' => now()],
            ['code' => '2025-2026 HK1', 'name' => 'Học kỳ I 2025-2026', 'start_date' => '2025-09-01', 'end_date' => '2025-12-31', 'created_at' => now(), 'updated_at' => now()],
            ['code' => '2025-2026 HK2', 'name' => 'Học kỳ II 2025-2026', 'start_date' => '2026-01-15', 'end_date' => '2026-05-31', 'created_at' => now(), 'updated_at' => now()],
        ];
        
        foreach ($semesters as $s) {
            DB::table('semesters')->updateOrInsert(['code' => $s['code']], $s);
        }
        echo "   ✓ Đã seed " . count($semesters) . " semester(s)\n";
    }
} else {
    echo "   - Tồn tại: NO\n";
}

echo "\n";

// 2. Kiểm tra assignments
echo "2. Bảng assignments:\n";
if (Schema::hasTable('assignments')) {
    $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
    $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
    
    echo "   - Có semester_id: " . ($hasSemesterId ? "YES" : "NO") . "\n";
    echo "   - Có semester_label: " . ($hasSemesterLabel ? "YES (cần xóa)" : "NO (OK)") . "\n";
    
    if (!$hasSemesterId && $hasSemesterLabel) {
        echo "   → Thêm semester_id...\n";
        DB::statement('ALTER TABLE assignments ADD COLUMN semester_id BIGINT UNSIGNED NULL AFTER academic_year');
        DB::statement('ALTER TABLE assignments ADD CONSTRAINT fk_assignments_semester_id FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE SET NULL');
        echo "   ✓ Đã thêm semester_id\n";
        
        // Migrate data
        echo "   → Migrate data từ semester_label sang semester_id...\n";
        $semester = DB::table('semesters')->where('code', '2025-2026 HK1')->first();
        if ($semester) {
            $updated = DB::table('assignments')
                ->where('semester_label', '2025-2026 HK1')
                ->update(['semester_id' => $semester->id]);
            echo "   ✓ Mapped {$updated} assignments\n";
        }
        
        // Set NOT NULL
        echo "   → Set semester_id NOT NULL...\n";
        DB::statement('ALTER TABLE assignments MODIFY semester_id BIGINT UNSIGNED NOT NULL');
        echo "   ✓ Đã set NOT NULL\n";
        
        // Xóa semester_label
        echo "   → Xóa semester_label...\n";
        DB::statement('ALTER TABLE assignments DROP COLUMN semester_label');
        echo "   ✓ Đã xóa semester_label\n";
    }
}

echo "\n=== HOÀN THÀNH ===\n";

