<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::dropIfExists('office_hours');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Không restore lại bảng vì đã xóa hoàn toàn
    }
};

