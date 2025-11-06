<?php
/**
 * Script kiểm tra database schema cho semesters và assignments
 * Chạy: php artisan tinker < check_db_final.php
 * Hoặc: php check_db_final.php (nếu có autoload)
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

echo "=== KIỂM TRA DATABASE SCHEMA ===\n\n";

try {
    // Kiểm tra bảng semesters
    echo "1. BẢNG semesters:\n";
    if (!Schema::hasTable('semesters')) {
        echo "    ❌ Bảng semesters KHÔNG TỒN TẠI\n";
    } else {
        echo "    ✅ Bảng semesters tồn tại\n";
        $columns = DB::select("
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT 
            FROM information_schema.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'semesters' 
            ORDER BY ORDINAL_POSITION
        ");
        echo "   Các cột:\n";
        foreach ($columns as $col) {
            $nullable = $col->IS_NULLABLE === 'YES' ? ' (nullable)' : '';
            $default = $col->COLUMN_DEFAULT ? " (default: {$col->COLUMN_DEFAULT})" : '';
            echo "     - {$col->COLUMN_NAME}: {$col->DATA_TYPE}{$nullable}{$default}\n";
        }
        $hasIsActive = Schema::hasColumn('semesters', 'is_active');
        echo "\n   ⚠️  Cột is_active: " . ($hasIsActive ? "CÓ ❌ (CẦN XÓA)" : "KHÔNG ✅ (OK)") . "\n";
    }
    
    // Kiểm tra bảng assignments
    echo "\n2. BẢNG assignments:\n";
    if (!Schema::hasTable('assignments')) {
        echo "    ❌ Bảng assignments KHÔNG TỒN TẠI\n";
    } else {
        echo "    ✅ Bảng assignments tồn tại\n";
        $columns = DB::select("
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT 
            FROM information_schema.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'assignments' 
            ORDER BY ORDINAL_POSITION
        ");
        echo "   Các cột:\n";
        foreach ($columns as $col) {
            $nullable = $col->IS_NULLABLE === 'YES' ? ' (nullable)' : '';
            $default = $col->COLUMN_DEFAULT ? " (default: {$col->COLUMN_DEFAULT})" : '';
            echo "     - {$col->COLUMN_NAME}: {$col->DATA_TYPE}{$nullable}{$default}\n";
        }
        $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
        $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
        echo "\n   ⚠️  Cột semester_label: " . ($hasSemesterLabel ? "CÓ ❌ (CẦN XÓA)" : "KHÔNG ✅ (OK)") . "\n";
        echo "   ✅ Cột semester_id: " . ($hasSemesterId ? "CÓ ✅ (OK)" : "KHÔNG ❌") . "\n";
        
        // Kiểm tra foreign key
        if ($hasSemesterId) {
            $foreignKeys = DB::select("
                SELECT CONSTRAINT_NAME 
                FROM information_schema.KEY_COLUMN_USAGE 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'assignments' 
                AND COLUMN_NAME = 'semester_id' 
                AND REFERENCED_TABLE_NAME = 'semesters'
                LIMIT 1
            ");
            echo "   ✅ Foreign key semester_id → semesters.id: " . (empty($foreignKeys) ? "KHÔNG ❌" : "CÓ ✅") . "\n";
        }
    }
    
    // Kiểm tra migrations đã chạy
    echo "\n3. MIGRATIONS ĐÃ CHẠY:\n";
    $migrations = DB::table('migrations')
        ->where(function($q) {
            $q->where('migration', 'like', '%semester%')
              ->orWhere('migration', 'like', '%assignment%');
        })
        ->orderBy('id')
        ->get();
    
    if ($migrations->isEmpty()) {
        echo "    ⚠️  Không tìm thấy migrations liên quan\n";
    } else {
        foreach ($migrations as $migration) {
            echo "     - {$migration->migration} (batch: {$migration->batch})\n";
        }
    }
    
    // Kiểm tra data
    echo "\n4. DỮ LIỆU:\n";
    if (Schema::hasTable('semesters')) {
        $semesterCount = DB::table('semesters')->count();
        echo "    ✅ Số lượng semesters: {$semesterCount}\n";
        if ($semesterCount > 0) {
            $semesters = DB::table('semesters')->select('id', 'code', 'name', 'start_date', 'end_date')->get();
            foreach ($semesters as $sem) {
                echo "       - {$sem->code}: {$sem->name} ({$sem->start_date} → {$sem->end_date})\n";
            }
        }
    }
    
    if (Schema::hasTable('assignments')) {
        $assignmentCount = DB::table('assignments')->count();
        echo "    ✅ Số lượng assignments: {$assignmentCount}\n";
        if ($assignmentCount > 0) {
            $nullSemesterId = DB::table('assignments')->whereNull('semester_id')->count();
            $withSemesterId = DB::table('assignments')->whereNotNull('semester_id')->count();
            echo "       - Có semester_id: {$withSemesterId}\n";
            echo "       - NULL semester_id: {$nullSemesterId}\n";
        }
    }
    
    echo "\n=== KẾT LUẬN ===\n";
    $hasIsActive = Schema::hasTable('semesters') && Schema::hasColumn('semesters', 'is_active');
    $hasSemesterLabel = Schema::hasTable('assignments') && Schema::hasColumn('assignments', 'semester_label');
    
    if ($hasIsActive || $hasSemesterLabel) {
        echo "❌ PHÁT HIỆN VẤN ĐỀ:\n";
        if ($hasIsActive) {
            echo "   - Bảng semesters vẫn có cột is_active\n";
        }
        if ($hasSemesterLabel) {
            echo "   - Bảng assignments vẫn có cột semester_label\n";
        }
        echo "\n📋 HÀNH ĐỘNG:\n";
        echo "   Chạy: php artisan migrate:fresh --seed\n";
    } else {
        echo "✅ TẤT CẢ ĐỀU ĐÚNG!\n";
        echo "   - Bảng semesters KHÔNG có is_active\n";
        echo "   - Bảng assignments KHÔNG có semester_label\n";
        echo "   - Bảng assignments có semester_id (foreign key)\n";
    }
    
} catch (\Exception $e) {
    echo "\n❌ LỖI: " . $e->getMessage() . "\n";
    echo "   File: " . $e->getFile() . "\n";
    echo "   Line: " . $e->getLine() . "\n";
    echo "\n⚠️  Kiểm tra:\n";
    echo "   1. Database có đang chạy không? (docker-compose up -d mysql)\n";
    echo "   2. File .env có đúng config DB_HOST không?\n";
    echo "   3. Có thể chạy: php artisan migrate:status\n";
}

