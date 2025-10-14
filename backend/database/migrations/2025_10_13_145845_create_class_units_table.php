<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('class_units', function (Blueprint $table) {
            $table->id();
            $table->string('code',50)->unique();
            $table->string('name',150);
            $table->string('cohort',20)->nullable();
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->integer('size')->default(0);
            $table->timestamps();
            $table->index('department_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('class_units');
    }
};
