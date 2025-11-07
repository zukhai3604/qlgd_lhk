<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('schedules', function (Blueprint $table) {
            $table->id();

            // Liên kết tới phân công giảng dạy
            $table->foreignId('assignment_id')
                ->constrained('assignments')
                ->cascadeOnDelete();

            // Thời gian và vị trí
            $table->date('session_date');
            $table->foreignId('timeslot_id')
                ->constrained('timeslots')
                ->restrictOnDelete();
            $table->foreignId('room_id')
                ->nullable()
                ->constrained('rooms')
                ->nullOnDelete();

            // Trạng thái buổi học
            $table->enum('status', [
                'PLANNED',          // Đã lên kế hoạch (mặc định)
                'TEACHING',         // Đang dạy
                'DONE',             // Đã dạy xong
                'MAKEUP_PLANNED',   // Lên lịch dạy bù
                'MAKEUP_DONE',      // Đã dạy bù xong
                'CANCELED'          // Đã hủy (do nghỉ)
            ])->default('PLANNED');

            // Buổi dạy bù (nếu có)
            $table->foreignId('makeup_of_id')
                ->nullable()
                ->constrained('schedules')
                ->nullOnDelete();

            // Ghi chú hoặc lý do hủy
            $table->string('note', 255)->nullable();

            $table->timestamps();

            // Unique đảm bảo 1 buổi học không trùng ca, ngày, phân công
            $table->unique(['assignment_id', 'session_date', 'timeslot_id'], 'uniq_assignment_date_slot');

            // Index giúp lọc nhanh theo tuần hoặc tình trạng
            $table->index(['session_date', 'status']);
        });
    }

    public function down(): void {
        Schema::dropIfExists('schedules');
    }
};
