<?php

/**
 * Script kiểm tra và sửa triệt để cả hai bảng semesters và assignments
 * Chạy: php artisan tinker < check_and_fix_both_tables.php
 */

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

echo "=== KIỂM TRA VÀ SỬA TRIỆT ĐỂ BẢNG semesters VÀ assignments ===\n\n";

// ===== KIỂM TRA BẢNG semesters =====
echo "1. KIỂM TRA BẢNG semesters:\n";
if (!Schema::hasTable('semesters')) {
    echo "   ❌ Bảng semesters chưa tồn tại!\n";
} else {
    $hasIsActive = Schema::hasColumn('semesters', 'is_active');
    echo "   - Có cột is_active: " . ($hasIsActive ? "CÓ (cần xóa)" : "KHÔNG (OK)") . "\n";
    
    if ($hasIsActive) {
        echo "   ⚠️  Đang xóa cột is_active...\n";
        
        // Xóa foreign key từ assignments nếu có
        if (Schema::hasTable('assignments')) {
            try {
                $foreignKeys = DB::select("
                    SELECT CONSTRAINT_NAME 
                    FROM information_schema.KEY_COLUMN_USAGE 
                    WHERE TABLE_SCHEMA = DATABASE() 
                    AND TABLE_NAME = 'assignments' 
                    AND COLUMN_NAME = 'semester_id' 
                    AND REFERENCED_TABLE_NAME = 'semesters'
                    LIMIT 1
                ");
                
                if (!empty($foreignKeys) && isset($foreignKeys[0]->CONSTRAINT_NAME)) {
                    $constraintName = $foreignKeys[0]->CONSTRAINT_NAME;
                    DB::statement("ALTER TABLE assignments DROP FOREIGN KEY `{$constraintName}`");
                    echo "   - Đã xóa foreign key: {$constraintName}\n";
                }
            } catch (\Exception $e) {
                echo "   - Lỗi khi xóa foreign key: " . $e->getMessage() . "\n";
            }
        }
        
        // Xóa cột is_active
        try {
            DB::statement('ALTER TABLE semesters DROP COLUMN is_active');
            echo "   ✓ Đã xóa cột is_active\n";
        } catch (\Exception $e) {
            echo "   ❌ Lỗi khi xóa cột is_active: " . $e->getMessage() . "\n";
        }
    }
}

// ===== KIỂM TRA BẢNG assignments =====
echo "\n2. KIỂM TRA BẢNG assignments:\n";
if (!Schema::hasTable('assignments')) {
    echo "   ❌ Bảng assignments chưa tồn tại!\n";
} else {
    $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
    $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
    
    echo "   - Có cột semester_label: " . ($hasSemesterLabel ? "CÓ (cần xóa)" : "KHÔNG (OK)") . "\n";
    echo "   - Có cột semester_id: " . ($hasSemesterId ? "CÓ (OK)" : "KHÔNG (cần thêm)") . "\n";
    
    if ($hasSemesterLabel) {
        echo "   ⚠️  Đang migrate data và xóa cột semester_label...\n";
        
        // Migrate data từ semester_label sang semester_id nếu có
        if (Schema::hasTable('semesters') && $hasSemesterId) {
            try {
                $semesterLabels = DB::table('assignments')
                    ->select('semester_label')
                    ->distinct()
                    ->whereNotNull('semester_label')
                    ->pluck('semester_label');
                
                foreach ($semesterLabels as $label) {
                    $semester = DB::table('semesters')
                        ->where('code', $label)
                        ->orWhere('name', $label)
                        ->first();
                    
                    if ($semester) {
                        DB::table('assignments')
                            ->where('semester_label', $label)
                            ->whereNull('semester_id')
                            ->update(['semester_id' => $semester->id]);
                    }
                }
                echo "   - Đã migrate data từ semester_label sang semester_id\n";
            } catch (\Exception $e) {
                echo "   - Lỗi khi migrate data: " . $e->getMessage() . "\n";
            }
        }
        
        // Xóa cột semester_label
        try {
            DB::statement('ALTER TABLE assignments DROP COLUMN semester_label');
            echo "   ✓ Đã xóa cột semester_label\n";
        } catch (\Exception $e) {
            echo "   ❌ Lỗi khi xóa cột semester_label: " . $e->getMessage() . "\n";
        }
    }
}

// ===== KIỂM TRA LẠI CUỐI CÙNG =====
echo "\n3. KIỂM TRA LẠI CUỐI CÙNG:\n";
if (Schema::hasTable('semesters')) {
    $hasIsActiveAfter = Schema::hasColumn('semesters', 'is_active');
    echo "   - Bảng semesters có is_active: " . ($hasIsActiveAfter ? "CÓ ❌" : "KHÔNG ✓") . "\n";
}

if (Schema::hasTable('assignments')) {
    $hasSemesterLabelAfter = Schema::hasColumn('assignments', 'semester_label');
    echo "   - Bảng assignments có semester_label: " . ($hasSemesterLabelAfter ? "CÓ ❌" : "KHÔNG ✓") . "\n";
}

echo "\n=== HOÀN THÀNH KIỂM TRA VÀ SỬA ===\n";

