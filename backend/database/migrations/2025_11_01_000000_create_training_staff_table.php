<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('training_staff', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->enum('gender', ['Nam','Nữ','Khác'])->nullable();
            $table->date('date_of_birth')->nullable();
            $table->enum('position', ['TRUONG_PHONG','PHO_PHONG','CAN_BO_DAO_TAO'])->default('CAN_BO_DAO_TAO');
            $table->string('avatar_url', 255)->nullable();
            $table->timestamps();

            $table->index('position');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('training_staff');
    }
};

