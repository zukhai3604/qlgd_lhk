<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {
        // Migration này chạy SAU khi cả semesters và assignments đã được tạo
        // Nó sẽ:
        // 1. Thêm foreign key constraint cho assignments.semester_id
        // 2. Set semester_id NOT NULL
        // 3. Migrate data từ semester_label sang semester_id (nếu có)
        // 4. Xóa semester_label (nếu có)
        
        if (!Schema::hasTable('semesters') || !Schema::hasTable('assignments')) {
            return; // Chưa có bảng, bỏ qua
        }
        
        // Bước 1: Migrate data từ semester_label sang semester_id nếu có
        if (Schema::hasColumn('assignments', 'semester_label')) {
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
            
            // Xóa semester_label sau khi migrate xong
            Schema::table('assignments', function (Blueprint $table) {
                $table->dropColumn('semester_label');
            });
        }
        
        // Bước 2: Thêm foreign key constraint nếu chưa có
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
            Schema::table('assignments', function (Blueprint $table) {
                $table->foreign('semester_id')->references('id')->on('semesters')->cascadeOnDelete();
            });
        }
        
        // Bước 3: Set semester_id NOT NULL sau khi đã migrate data
        try {
            DB::statement('ALTER TABLE assignments MODIFY semester_id BIGINT UNSIGNED NOT NULL');
        } catch (\Exception $e) {
            // Ignore nếu đã NOT NULL hoặc có lỗi
        }
    }
    
    public function down(): void {
        // Không rollback - giữ nguyên cấu trúc đúng
    }
};

