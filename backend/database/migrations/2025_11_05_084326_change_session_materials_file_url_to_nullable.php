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
        // Thay đổi file_url thành nullable
        DB::statement('ALTER TABLE session_materials MODIFY COLUMN file_url VARCHAR(500) NULL');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Rollback về NOT NULL
        DB::statement('ALTER TABLE session_materials MODIFY COLUMN file_url VARCHAR(500) NOT NULL');
    }
};
