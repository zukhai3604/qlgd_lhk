<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('departments', function (Blueprint $table) {
            $table->id();
            $table->string('code',50)->unique();
            $table->string('name',150);
            $table->foreignId('faculty_id')->nullable()->constrained('faculties')->nullOnDelete();
            $table->timestamps();
            $table->index('faculty_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('departments');
    }
};
