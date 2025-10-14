<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('rooms', function (Blueprint $table) {
            $table->id();
            $table->string('code',50)->unique();
            $table->string('building',50)->nullable();
            $table->integer('capacity')->nullable();
            $table->enum('room_type',['LT','TH','LAB','OTHER'])->default('LT');
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('rooms');
    }
};
