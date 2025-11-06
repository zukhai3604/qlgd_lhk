<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('assignments') || !Schema::hasTable('semesters')) {
            return;
        }
        
        // Bước 1: Thêm semester_id nếu chưa có
        if (!Schema::hasColumn('assignments', 'semester_id')) {
            Schema::table('assignments', function (Blueprint $table) {
                $table->unsignedBigInteger('semester_id')->nullable()->after('class_unit_id');
            });
        }
        
        // Bước 2: Migrate data từ semester_label sang semester_id nếu có semester_label
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
        }
        
        // Bước 3: Xóa semester_label sau khi migrate xong
        if (Schema::hasColumn('assignments', 'semester_label')) {
            Schema::table('assignments', function (Blueprint $table) {
                $table->dropColumn('semester_label');
            });
        }
        
        // Bước 4: Thêm foreign key constraint nếu chưa có
        $foreignKeys = DB::select("
            SELECT CONSTRAINT_NAME 
            FROM information_schema.KEY_COLUMN_USAGE 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'assignments' 
            AND COLUMN_NAME = 'semester_id' 
            AND REFERENCED_TABLE_NAME = 'semesters'
            LIMIT 1
        ");
        
        if (empty($foreignKeys) && Schema::hasColumn('assignments', 'semester_id')) {
            Schema::table('assignments', function (Blueprint $table) {
                $table->foreign('semester_id')->references('id')->on('semesters')->cascadeOnDelete();
            });
        }
        
        // Bước 5: Set semester_id NOT NULL sau khi đã migrate data
        if (Schema::hasColumn('assignments', 'semester_id')) {
            try {
                DB::statement('ALTER TABLE assignments MODIFY semester_id BIGINT UNSIGNED NOT NULL');
            } catch (\Exception $e) {
                // Ignore nếu đã NOT NULL hoặc có lỗi
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Không rollback - giữ nguyên cấu trúc đúng
    }
};
