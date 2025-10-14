<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('session_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('schedule_id')->constrained('schedules')->cascadeOnDelete();
            $table->string('topic',200)->nullable();
            $table->text('content')->nullable();
            $table->string('evidence_url',500)->nullable();
            $table->timestamps();
            $table->index('schedule_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('session_notes');
    }
};
