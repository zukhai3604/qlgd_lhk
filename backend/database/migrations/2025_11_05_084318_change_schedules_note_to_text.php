<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Thay đổi note từ VARCHAR(255) → TEXT
        DB::statement('ALTER TABLE schedules MODIFY COLUMN note TEXT NULL');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Rollback về VARCHAR(255)
        DB::statement('ALTER TABLE schedules MODIFY COLUMN note VARCHAR(255) NULL');
    }
};
