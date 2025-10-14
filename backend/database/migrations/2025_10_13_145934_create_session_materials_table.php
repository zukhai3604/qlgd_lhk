<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('session_materials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('schedule_id')->constrained('schedules')->cascadeOnDelete();
            $table->string('title',200)->nullable();
            $table->string('file_url',500);
            $table->string('file_type',50)->nullable();
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('uploaded_at')->useCurrent();
            $table->index('schedule_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('session_materials');
    }
};
