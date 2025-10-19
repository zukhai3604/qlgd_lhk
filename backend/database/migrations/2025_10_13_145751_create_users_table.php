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
        Schema::create('users', function (Blueprint $table) {
            $table->id();

            // ===== Thông tin cá nhân =====
            $table->string('name', 150);
            $table->date('date_of_birth')->nullable();
            $table->enum('gender', ['Nam', 'Nữ', 'Khác'])->nullable();
            $table->string('phone', 30)->nullable();
            $table->string('email', 190)->unique();
            $table->string('avatar', 255)->nullable();

            // ===== Học thuật / nghề nghiệp =====
            $table->string('department', 100)->nullable(); // Bộ môn
            $table->string('faculty', 100)->nullable();    // Khoa

            // ===== Đăng nhập & phân quyền =====
            $table->string('password');
            $table->enum('role', ['ADMIN', 'DAO_TAO', 'GIANG_VIEN'])->default('GIANG_VIEN');
            $table->boolean('is_active')->default(true);

            // ===== Laravel Auth =====
            $table->rememberToken();

            // ===== Thời gian =====
            $table->timestamps();

            // ===== Index =====
            $table->index('role');
            $table->index('faculty');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
