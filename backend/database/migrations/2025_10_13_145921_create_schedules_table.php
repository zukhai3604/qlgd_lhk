<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('assignment_id')->constrained('assignments')->cascadeOnDelete();
            $table->date('session_date');
            $table->foreignId('timeslot_id')->constrained('timeslots')->restrictOnDelete();
            $table->foreignId('room_id')->nullable()->constrained('rooms')->nullOnDelete();
            $table->enum('status',['PLANNED','TAUGHT','ABSENT','MAKEUP','CANCELED'])->default('PLANNED');
            $table->foreignId('makeup_of_id')->nullable()->constrained('schedules')->nullOnDelete();
            $table->timestamps();

            $table->unique(['assignment_id','session_date','timeslot_id']);
            $table->index(['session_date','status']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('schedules');
    }
};
