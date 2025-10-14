<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('leave_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('schedule_id')->constrained('schedules')->cascadeOnDelete();
            $table->foreignId('lecturer_id')->constrained('lecturers')->cascadeOnDelete();
            $table->text('reason');
            $table->string('proof_url',500)->nullable();
            $table->enum('status',['PENDING','APPROVED','REJECTED'])->default('PENDING');
            $table->timestamp('requested_at')->useCurrent();
            $table->timestamp('decided_at')->nullable();
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['schedule_id','lecturer_id']);
            $table->index(['status','requested_at']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('leave_requests');
    }
};
