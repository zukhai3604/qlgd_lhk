<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('leave_requests', function (Blueprint $table) {
            $table->id();

            // buổi học xin nghỉ
            $table->foreignId('schedule_id')
                  ->constrained('schedules')->cascadeOnDelete();
            // giảng viên (qua lecturer)
            $table->foreignId('lecturer_id')
                  ->constrained('lecturers')->cascadeOnDelete();

            $table->string('reason', 255);

            // chờ duyệt | đã duyệt | từ chối | hủy
            $table->enum('status', ['PENDING','APPROVED','REJECTED','CANCELED'])
                  ->default('PENDING');
            // người duyệt (phòng đào tạo)
            $table->foreignId('approved_by')->nullable()
                  ->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->string('note', 255)->nullable();
            $table->timestamps();
            // Mỗi lịch + mỗi GV chỉ có 1 yêu cầu pending
            $table->unique(['schedule_id', 'lecturer_id', 'status'], 'uniq_sched_lec_pending')
                  ->where('status', 'PENDING');
        });
    }

    public function down(): void {
        Schema::dropIfExists('leave_requests');
    }
};
