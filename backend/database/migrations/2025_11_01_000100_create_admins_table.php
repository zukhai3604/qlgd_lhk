<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            
            // Thông tin cá nhân
            $table->enum('gender', ['Nam','Nữ','Khác'])->nullable();
            $table->date('date_of_birth')->nullable();
            $table->string('email', 100)->nullable();
            $table->string('phone', 20)->nullable();
            $table->text('address')->nullable()->comment('Địa chỉ');
            $table->string('citizen_id', 20)->nullable()->comment('Số CCCD/CMND');
            
            // Media
            $table->string('avatar_url', 255)->nullable();
            
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admins');
    }
};

