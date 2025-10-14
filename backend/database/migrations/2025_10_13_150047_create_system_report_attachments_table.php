<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('system_report_attachments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained('system_reports')->cascadeOnDelete();
            $table->string('file_url',500);
            $table->string('file_type',50)->nullable();
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('uploaded_at')->useCurrent();
            $table->index('report_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('system_report_attachments');
    }
};
