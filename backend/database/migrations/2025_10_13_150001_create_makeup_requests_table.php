<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('makeup_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('leave_request_id')->constrained('leave_requests')->cascadeOnDelete();
            $table->date('suggested_date');
            $table->foreignId('timeslot_id')->constrained('timeslots')->restrictOnDelete();
            $table->foreignId('room_id')->nullable()->constrained('rooms')->nullOnDelete();
            $table->string('note',255)->nullable();
            $table->enum('status',['PENDING','APPROVED','REJECTED'])->default('PENDING');
            $table->timestamp('decided_at')->nullable();
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['status','suggested_date']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('makeup_requests');
    }
};
