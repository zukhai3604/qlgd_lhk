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

            // Thông tin cơ bản
            $table->string('name', 150);
            $table->string('email', 190)->unique();
            $table->string('phone', 30)->nullable();

            // Mật khẩu và phân quyền
            $table->string('password');
            $table->enum('role', ['ADMIN', 'DAO_TAO', 'GIANG_VIEN'])
                  ->default('GIANG_VIEN');
            $table->boolean('is_active')->default(true);

            // Token để nhớ đăng nhập (Laravel Auth)
            $table->rememberToken();

            // Thời gian tạo & cập nhật
            $table->timestamps();

            // Index giúp truy vấn nhanh hơn
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
