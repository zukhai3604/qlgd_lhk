<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('attendance_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('schedule_id')->constrained('schedules')->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->enum('status',['PRESENT','ABSENT','LATE','EXCUSED'])->default('PRESENT');
            $table->string('note',255)->nullable();
            $table->foreignId('marked_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('marked_at')->useCurrent();
            $table->unique(['schedule_id','student_id']);
            $table->index(['schedule_id','student_id','status']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('attendance_records');
    }
};
