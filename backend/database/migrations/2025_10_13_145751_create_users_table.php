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

            // ===== Thông tin tài khoản (tối thiểu) =====
            $table->string('name', 150);
            $table->string('phone', 30)->nullable();
            $table->string('email', 190)->unique();

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
