<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('from_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('to_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title',200);
            $table->text('body')->nullable();
            $table->enum('type',['LEAVE_REQUEST','MAKEUP_REQUEST','LEAVE_RESPONSE','MAKEUP_RESPONSE','SCHEDULE_CHANGE','ERROR_REPORT','GENERAL'])->default('GENERAL');
            $table->enum('status',['UNREAD','READ'])->default('UNREAD');
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('read_at')->nullable();
            $table->index(['to_user_id','type','status','created_at']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('notifications');
    }
};
