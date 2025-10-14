<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('timeslots', function (Blueprint $table) {
            $table->id();
            $table->string('code',30)->unique();
            $table->tinyInteger('day_of_week'); // 1..7 (Mon..Sun)
            $table->time('start_time');
            $table->time('end_time');
            $table->timestamps();
            $table->index('day_of_week');
        });
    }
    public function down(): void {
        Schema::dropIfExists('timeslots');
    }
};
