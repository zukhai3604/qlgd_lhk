<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Unique composite to avoid duplicate frames within a day
        Schema::table('timeslots', function (Blueprint $table) {
            $table->unique(['day_of_week', 'start_time', 'end_time'], 'uniq_timeslots_day_time');
        });

        // Add a simple CHECK (start_time < end_time).
        // MySQL < 8.0.16 ignores CHECKs; MySQL 8+ enforces it. Other engines may throw.
        // Be permissive to keep migration portable.
        try {
            DB::unprepared("ALTER TABLE `timeslots` ADD CONSTRAINT `chk_timeslots_time` CHECK (`start_time` < `end_time`)");
        } catch (\Throwable $e) {
            // ignore if not supported or already exists
        }
    }

    public function down(): void
    {
        // Drop CHECK if exists (MySQL allows DROP CHECK by name on 8+)
        try {
            DB::unprepared("ALTER TABLE `timeslots` DROP CHECK `chk_timeslots_time`");
        } catch (\Throwable $e) {
            // ignore for engines not supporting CHECK
        }

        Schema::table('timeslots', function (Blueprint $table) {
            // Drop unique index by name
            try {
                $table->dropUnique('uniq_timeslots_day_time');
            } catch (\Throwable $e) {
                // ignore if it doesn't exist
            }
        });
    }
};
