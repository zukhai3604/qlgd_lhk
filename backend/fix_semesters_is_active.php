<?php
/**
 * Script để kiểm tra và xóa cột is_active khỏi bảng semesters
 * Chạy: php artisan tinker < fix_semesters_is_active.php
 * Hoặc: php -r "require 'vendor/autoload.php'; require 'fix_semesters_is_active.php';"
 */

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Artisan;

echo "=== KIỂM TRA VÀ XÓA CỘT is_active TRONG BẢNG semesters ===\n\n";

// Kiểm tra xem có bảng semesters không
if (!Schema::hasTable('semesters')) {
    echo "❌ Bảng semesters không tồn tại!\n";
    exit(1);
}

echo "✓ Bảng semesters tồn tại\n";

// Kiểm tra xem có cột is_active không
$hasIsActive = Schema::hasColumn('semesters', 'is_active');

if (!$hasIsActive) {
    echo "✓ Bảng semesters KHÔNG có cột is_active - OK!\n";
    exit(0);
}

echo "⚠️  Bảng semesters CÓ cột is_active - Đang xóa...\n\n";

// Lấy danh sách các cột hiện tại
$columns = Schema::getColumnListing('semesters');
echo "Các cột hiện tại: " . implode(', ', $columns) . "\n\n";

// Xóa foreign key từ assignments nếu có
if (Schema::hasTable('assignments')) {
    try {
        // Lấy tên foreign key constraint
        $foreignKeys = DB::select("
            SELECT CONSTRAINT_NAME 
            FROM information_schema.KEY_COLUMN_USAGE 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'assignments' 
            AND COLUMN_NAME = 'semester_id' 
            AND REFERENCED_TABLE_NAME = 'semesters'
        ");
        
        if (!empty($foreignKeys)) {
            $constraintName = $foreignKeys[0]->CONSTRAINT_NAME;
            echo "Đang xóa foreign key: $constraintName\n";
            DB::statement("ALTER TABLE assignments DROP FOREIGN KEY `$constraintName`");
            echo "✓ Đã xóa foreign key\n\n";
        }
    } catch (\Exception $e) {
        echo "⚠️  Không thể xóa foreign key (có thể không tồn tại): " . $e->getMessage() . "\n\n";
    }
}

// Xóa cột is_active
try {
    echo "Đang xóa cột is_active...\n";
    DB::statement('ALTER TABLE semesters DROP COLUMN is_active');
    echo "✓ Đã xóa cột is_active thành công!\n\n";
} catch (\Exception $e) {
    echo "❌ Lỗi khi xóa cột is_active: " . $e->getMessage() . "\n";
    echo "Đang thử cách khác...\n\n";
    
    // Thử cách khác: dùng Schema facade
    try {
        Schema::table('semesters', function ($table) {
            $table->dropColumn('is_active');
        });
        echo "✓ Đã xóa cột is_active bằng Schema facade!\n\n";
    } catch (\Exception $e2) {
        echo "❌ Lỗi khi dùng Schema facade: " . $e2->getMessage() . "\n\n";
        exit(1);
    }
}

// Kiểm tra lại
$hasIsActiveAfter = Schema::hasColumn('semesters', 'is_active');
if (!$hasIsActiveAfter) {
    echo "✓ XÁC NHẬN: Bảng semesters KHÔNG còn cột is_active!\n\n";
} else {
    echo "❌ VẪN CÒN: Bảng semesters vẫn có cột is_active!\n\n";
    exit(1);
}

// Thêm lại foreign key nếu cần
if (Schema::hasTable('assignments')) {
    try {
        $hasForeignKey = false;
        $foreignKeys = DB::select("
            SELECT CONSTRAINT_NAME 
            FROM information_schema.KEY_COLUMN_USAGE 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'assignments' 
            AND COLUMN_NAME = 'semester_id' 
            AND REFERENCED_TABLE_NAME = 'semesters'
        ");
        
        if (empty($foreignKeys)) {
            echo "Đang thêm lại foreign key...\n";
            Schema::table('assignments', function ($table) {
                $table->foreign('semester_id')->references('id')->on('semesters')->cascadeOnDelete();
            });
            echo "✓ Đã thêm lại foreign key\n\n";
        }
    } catch (\Exception $e) {
        echo "⚠️  Không thể thêm lại foreign key: " . $e->getMessage() . "\n\n";
    }
}

// Hiển thị cấu trúc bảng sau khi sửa
echo "=== CẤU TRÚC BẢNG SAU KHI SỬA ===\n";
$columnsAfter = Schema::getColumnListing('semesters');
foreach ($columnsAfter as $column) {
    $columnType = DB::select("SHOW COLUMNS FROM semesters WHERE Field = '$column'")[0];
    echo "  - $column: {$columnType->Type}\n";
}

echo "\n=== HOÀN THÀNH ===\n";

