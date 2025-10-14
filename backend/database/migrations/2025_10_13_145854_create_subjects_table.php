<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('subjects', function (Blueprint $table) {
            $table->id();
            $table->string('code',50)->unique();
            $table->string('name',200);
            $table->integer('credits');
            $table->integer('total_sessions');
            $table->integer('theory_hours')->default(0);
            $table->integer('practice_hours')->default(0);
            $table->string('semester_label',50)->nullable();
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->timestamps();
            $table->index('department_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('subjects');
    }
};
