<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('lecturers', function (Blueprint $table) {
            $table->id();

            // Liên kết 1-1 với users
            $table->foreignId('user_id')->unique()
                  ->constrained('users')->cascadeOnDelete();

            // Hồ sơ giảng viên
            $table->enum('gender', ['Nam', 'Nữ', 'Khác'])->nullable();
            $table->date('date_of_birth')->nullable();

            // Bộ môn/khoa
            $table->foreignId('department_id')
                  ->nullable()
                  ->constrained('departments')->nullOnDelete();

            // Ảnh đại diện
            $table->string('avatar_url', 255)->nullable();

            $table->timestamps();

            // index phụ (nếu cần)
            $table->index(['department_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lecturers');
    }
};
