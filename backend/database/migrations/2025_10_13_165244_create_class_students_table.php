<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('class_students', function (Blueprint $table) {
            $table->id();
            $table->foreignId('class_unit_id')->constrained('class_units')->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->timestamp('joined_at')->nullable();
            $table->unique(['class_unit_id','student_id']);
            $table->index('class_unit_id');
            $table->index('student_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('class_students');
    }
};
