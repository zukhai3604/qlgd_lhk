<?php

/**
 * Script kiểm tra database schema thực tế
 * 
 * CÁCH CHẠY:
 * 1. Đảm bảo database đang chạy (Docker hoặc MySQL)
 * 2. Chạy: php artisan tinker
 * 3. Copy-paste toàn bộ nội dung từ dòng "use Illuminate..." đến cuối file vào tinker
 * 
 * HOẶC:
 * php artisan tinker < check_db_schema.php
 */

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

echo "=== KIỂM TRA DATABASE SCHEMA THỰC TẾ ===\n\n";

try {
    // Kiểm tra kết nối database
    DB::connection()->getPdo();
    echo "✓ Kết nối database thành công\n\n";
} catch (\Exception $e) {
    echo "❌ Lỗi kết nối database: " . $e->getMessage() . "\n";
    echo "Vui lòng kiểm tra:\n";
    echo "  - Database đang chạy\n";
    echo "  - File .env đã cấu hình đúng\n";
    exit(1);
}

// ===== KIỂM TRA BẢNG semesters =====
echo "1. BẢNG semesters:\n";
if (!Schema::hasTable('semesters')) {
    echo "   ❌ Bảng semesters KHÔNG TỒN TẠI\n";
} else {
    echo "   ✓ Bảng semesters tồn tại\n";
    
    // Lấy tất cả các cột trong bảng
    $columns = DB::select("
        SELECT 
            COLUMN_NAME,
            DATA_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            COLUMN_KEY
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'semesters'
        ORDER BY ORDINAL_POSITION
    ");
    
    echo "   Các cột trong bảng:\n";
    foreach ($columns as $col) {
        $nullable = $col->IS_NULLABLE === 'YES' ? 'NULL' : 'NOT NULL';
        $default = $col->COLUMN_DEFAULT !== null ? " DEFAULT '{$col->COLUMN_DEFAULT}'" : '';
        $key = $col->COLUMN_KEY ? " ({$col->COLUMN_KEY})" : '';
        echo "     - {$col->COLUMN_NAME}: {$col->DATA_TYPE} {$nullable}{$default}{$key}\n";
    }
    
    // Kiểm tra cụ thể is_active
    $hasIsActive = Schema::hasColumn('semesters', 'is_active');
    echo "\n   ⚠️  Kiểm tra cột is_active: " . ($hasIsActive ? "CÓ ❌ (CẦN XÓA)" : "KHÔNG ✓") . "\n";
    
    if ($hasIsActive) {
        // Lấy thông tin chi tiết về cột is_active
        $isActiveInfo = DB::select("
            SELECT 
                COLUMN_NAME,
                DATA_TYPE,
                IS_NULLABLE,
                COLUMN_DEFAULT,
                COLUMN_TYPE
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'semesters'
            AND COLUMN_NAME = 'is_active'
        ");
        
        if (!empty($isActiveInfo)) {
            $info = $isActiveInfo[0];
            echo "   Chi tiết cột is_active:\n";
            echo "     - Kiểu dữ liệu: {$info->DATA_TYPE}\n";
            echo "     - Có thể NULL: {$info->IS_NULLABLE}\n";
            echo "     - Giá trị mặc định: " . ($info->COLUMN_DEFAULT ?? 'NULL') . "\n";
            echo "     - COLUMN_TYPE: {$info->COLUMN_TYPE}\n";
        }
    }
}

// ===== KIỂM TRA BẢNG assignments =====
echo "\n2. BẢNG assignments:\n";
if (!Schema::hasTable('assignments')) {
    echo "   ❌ Bảng assignments KHÔNG TỒN TẠI\n";
} else {
    echo "   ✓ Bảng assignments tồn tại\n";
    
    // Lấy tất cả các cột trong bảng
    $columns = DB::select("
        SELECT 
            COLUMN_NAME,
            DATA_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            COLUMN_KEY
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'assignments'
        ORDER BY ORDINAL_POSITION
    ");
    
    echo "   Các cột trong bảng:\n";
    foreach ($columns as $col) {
        $nullable = $col->IS_NULLABLE === 'YES' ? 'NULL' : 'NOT NULL';
        $default = $col->COLUMN_DEFAULT !== null ? " DEFAULT '{$col->COLUMN_DEFAULT}'" : '';
        $key = $col->COLUMN_KEY ? " ({$col->COLUMN_KEY})" : '';
        echo "     - {$col->COLUMN_NAME}: {$col->DATA_TYPE} {$nullable}{$default}{$key}\n";
    }
    
    // Kiểm tra cụ thể semester_label và semester_id
    $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
    $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
    
    echo "\n   ⚠️  Kiểm tra cột semester_label: " . ($hasSemesterLabel ? "CÓ ❌ (CẦN XÓA)" : "KHÔNG ✓") . "\n";
    echo "   ✓ Kiểm tra cột semester_id: " . ($hasSemesterId ? "CÓ ✓" : "KHÔNG ❌") . "\n";
    
    if ($hasSemesterLabel) {
        // Lấy thông tin chi tiết về cột semester_label
        $semesterLabelInfo = DB::select("
            SELECT 
                COLUMN_NAME,
                DATA_TYPE,
                IS_NULLABLE,
                COLUMN_DEFAULT,
                COLUMN_TYPE,
                CHARACTER_MAXIMUM_LENGTH
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'assignments'
            AND COLUMN_NAME = 'semester_label'
        ");
        
        if (!empty($semesterLabelInfo)) {
            $info = $semesterLabelInfo[0];
            echo "   Chi tiết cột semester_label:\n";
            echo "     - Kiểu dữ liệu: {$info->DATA_TYPE}\n";
            echo "     - Độ dài tối đa: " . ($info->CHARACTER_MAXIMUM_LENGTH ?? 'N/A') . "\n";
            echo "     - Có thể NULL: {$info->IS_NULLABLE}\n";
            echo "     - Giá trị mặc định: " . ($info->COLUMN_DEFAULT ?? 'NULL') . "\n";
            echo "     - COLUMN_TYPE: {$info->COLUMN_TYPE}\n";
        }
    }
    
    // Kiểm tra foreign key
    $foreignKeys = DB::select("
        SELECT 
            CONSTRAINT_NAME,
            COLUMN_NAME,
            REFERENCED_TABLE_NAME,
            REFERENCED_COLUMN_NAME
        FROM information_schema.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'assignments'
        AND REFERENCED_TABLE_NAME IS NOT NULL
    ");
    
    if (!empty($foreignKeys)) {
        echo "\n   Foreign keys:\n";
        foreach ($foreignKeys as $fk) {
            echo "     - {$fk->CONSTRAINT_NAME}: {$fk->COLUMN_NAME} -> {$fk->REFERENCED_TABLE_NAME}.{$fk->REFERENCED_COLUMN_NAME}\n";
        }
    } else {
        echo "\n   ⚠️  Không có foreign key nào\n";
    }
}

// ===== KIỂM TRA MIGRATIONS ĐÃ CHẠY =====
echo "\n3. MIGRATIONS ĐÃ CHẠY:\n";
try {
    $migrations = DB::table('migrations')
        ->where('migration', 'like', '%semester%')
        ->orWhere('migration', 'like', '%assignment%')
        ->orderBy('id')
        ->get();
    
    if ($migrations->isEmpty()) {
        echo "   ⚠️  Không tìm thấy migrations liên quan\n";
    } else {
        echo "   Các migrations đã chạy:\n";
        foreach ($migrations as $migration) {
            echo "     - {$migration->migration} (batch: {$migration->batch})\n";
        }
    }
} catch (\Exception $e) {
    echo "   ❌ Lỗi khi kiểm tra migrations: " . $e->getMessage() . "\n";
}

// ===== KIỂM TRA DỮ LIỆU MẪU =====
echo "\n4. DỮ LIỆU MẪU:\n";
if (Schema::hasTable('semesters')) {
    $semesterCount = DB::table('semesters')->count();
    echo "   - Số lượng semesters: {$semesterCount}\n";
    if ($semesterCount > 0) {
        $sampleSemester = DB::table('semesters')->first();
        echo "   - Mẫu semester đầu tiên:\n";
        foreach ((array)$sampleSemester as $key => $value) {
            echo "     {$key}: " . ($value ?? 'NULL') . "\n";
        }
    }
}

if (Schema::hasTable('assignments')) {
    $assignmentCount = DB::table('assignments')->count();
    echo "   - Số lượng assignments: {$assignmentCount}\n";
    if ($assignmentCount > 0) {
        $sampleAssignment = DB::table('assignments')->first();
        echo "   - Mẫu assignment đầu tiên:\n";
        foreach ((array)$sampleAssignment as $key => $value) {
            echo "     {$key}: " . ($value ?? 'NULL') . "\n";
        }
    }
}

echo "\n=== HOÀN THÀNH KIỂM TRA ===\n";
echo "\n⚠️  NẾU PHÁT HIỆN CÓ is_active HOẶC semester_label:\n";
echo "   Chạy: php artisan migrate:fresh --seed\n";
echo "   Hoặc: php artisan migrate --path=database/migrations/2025_11_06_000000_remove_is_active_from_semesters_final.php\n";
echo "         php artisan migrate --path=database/migrations/2025_11_06_000001_remove_semester_label_from_assignments_final.php\n";
