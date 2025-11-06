<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Xóa cột is_active từ bảng semesters nếu có
        if (Schema::hasTable('semesters') && Schema::hasColumn('semesters', 'is_active')) {
            Schema::table('semesters', function (Blueprint $table) {
                $table->dropColumn('is_active');
            });
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
