<?php
// Script để chạy trực tiếp trong Docker container
// Copy nội dung này vào tinker hoặc chạy: php artisan tinker
// Sau đó paste code này vào

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

echo "=== KIỂM TRA VÀ XÓA CỘT is_active ===\n\n";

if (!Schema::hasTable('semesters')) {
    echo "❌ Bảng semesters không tồn tại!\n";
    exit(1);
}

$hasIsActive = Schema::hasColumn('semesters', 'is_active');
echo "Có cột is_active: " . ($hasIsActive ? "CÓ" : "KHÔNG") . "\n\n";

if (!$hasIsActive) {
    echo "✓ Bảng semesters không có cột is_active - OK!\n";
    exit(0);
}

echo "⚠️  Đang xóa cột is_active...\n\n";

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
        
        if (!empty($foreignKeys)) {
            $constraintName = $foreignKeys[0]->CONSTRAINT_NAME;
            DB::statement("ALTER TABLE assignments DROP FOREIGN KEY `{$constraintName}`");
            echo "✓ Đã xóa foreign key: {$constraintName}\n";
        }
    } catch (\Exception $e) {
        echo "⚠️  Không có foreign key để xóa\n";
    }
}

// Xóa cột is_active
try {
    DB::statement('ALTER TABLE semesters DROP COLUMN is_active');
    echo "✓ Đã xóa cột is_active bằng SQL trực tiếp\n";
} catch (\Exception $e) {
    try {
        Schema::table('semesters', function ($table) {
            $table->dropColumn('is_active');
        });
        echo "✓ Đã xóa cột is_active bằng Schema facade\n";
    } catch (\Exception $e2) {
        echo "❌ Lỗi: " . $e2->getMessage() . "\n";
        exit(1);
    }
}

// Kiểm tra lại
$hasIsActiveAfter = Schema::hasColumn('semesters', 'is_active');
if (!$hasIsActiveAfter) {
    echo "\n✓ XÁC NHẬN: Bảng semesters KHÔNG còn cột is_active!\n";
} else {
    echo "\n❌ VẪN CÒN: Bảng semesters vẫn có cột is_active!\n";
    exit(1);
}

// Thêm lại foreign key nếu cần
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
        
        if (empty($foreignKeys)) {
            Schema::table('assignments', function ($table) {
                $table->foreign('semester_id')->references('id')->on('semesters')->cascadeOnDelete();
            });
            echo "✓ Đã thêm lại foreign key\n";
        }
    } catch (\Exception $e) {
        echo "⚠️  Không thể thêm lại foreign key: " . $e->getMessage() . "\n";
    }
}

echo "\n=== HOÀN THÀNH ===\n";

