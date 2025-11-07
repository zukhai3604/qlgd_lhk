<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (Schema::hasTable('office_hours')) return;
        Schema::create('office_hours', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lecturer_id')->constrained('lecturers')->cascadeOnDelete();
            $table->unsignedTinyInteger('weekday'); // 0..6
            $table->time('start_time');
            $table->time('end_time');
            $table->string('location', 120)->nullable();
            $table->string('repeat_rule', 120)->nullable();
            $table->string('note', 255)->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->index(['lecturer_id','weekday']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('office_hours');
    }
};

