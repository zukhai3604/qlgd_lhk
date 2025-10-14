<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('system_report_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained('system_reports')->cascadeOnDelete();
            $table->foreignId('author_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('body');
            $table->timestamp('created_at')->useCurrent();
            $table->index('report_id');
        });
    }
    public function down(): void {
        Schema::dropIfExists('system_report_comments');
    }
};
