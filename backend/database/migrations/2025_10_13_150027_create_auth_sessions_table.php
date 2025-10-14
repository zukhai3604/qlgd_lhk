<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('auth_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('login_at')->useCurrent();
            $table->timestamp('logout_at')->nullable();
            $table->string('ip_address',64)->nullable();
            $table->string('device_info',255)->nullable();
            $table->string('jwt_id',128)->nullable();
            $table->boolean('revoked')->default(false);
            $table->index(['user_id','login_at']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('auth_sessions');
    }
};
