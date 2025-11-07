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
    Schema::table('lecturers', function (Blueprint $table) {
        $table->string('department_name', 100)->nullable()->after('department_id');
        $table->string('faculty_name', 100)->nullable()->after('department_name');
    });
}

public function down(): void
{
    Schema::table('lecturers', function (Blueprint $table) {
        $table->dropColumn(['department_name', 'faculty_name']);
    });
}

};
