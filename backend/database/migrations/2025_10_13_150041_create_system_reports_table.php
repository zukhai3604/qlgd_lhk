<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('system_reports', function (Blueprint $table) {
            $table->id();
            $table->enum('source_type',['GIANG_VIEN','DAO_TAO','GUEST']);
            $table->foreignId('reporter_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('contact_email',190)->nullable();
            $table->string('title',200);
            $table->text('description');
            $table->enum('category',['BUG','FEEDBACK','DATA_ISSUE','PERFORMANCE','SECURITY','OTHER'])->default('OTHER');
            $table->enum('severity',['LOW','MEDIUM','HIGH','CRITICAL'])->default('LOW');
            $table->enum('status',['NEW','IN_REVIEW','ACK','RESOLVED','REJECTED'])->default('NEW');
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->foreignId('closed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->index(['status','severity','source_type','category']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('system_reports');
    }
};
