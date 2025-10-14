<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lecturer_id')->constrained('lecturers')->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained('subjects')->cascadeOnDelete();
            $table->foreignId('class_unit_id')->constrained('class_units')->cascadeOnDelete();
            $table->string('semester_label',50);
            $table->string('academic_year',20)->nullable();
            $table->timestamps();
            $table->index(['lecturer_id','subject_id','class_unit_id']);
            $table->index(['semester_label','academic_year']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('assignments');
    }
};
