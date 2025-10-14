<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('code',50)->unique();
            $table->string('full_name',150);
            $table->string('email',190)->nullable();
            $table->string('phone',30)->nullable();
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->timestamps();
            $table->index('full_name');
        });
    }
    public function down(): void {
        Schema::dropIfExists('students');
    }
};
