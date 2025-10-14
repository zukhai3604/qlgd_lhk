<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('lecturers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->string('degree',50)->nullable();
            $table->string('phone',30)->nullable();
            $table->timestamps();
            $table->index('department_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('lecturers');
    }
};
