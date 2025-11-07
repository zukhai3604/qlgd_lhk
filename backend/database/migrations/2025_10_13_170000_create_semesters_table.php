<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void {

return new class extends Migration {
    public function up(): void {
        if (Schema::hasTable('semesters')) return;
        Schema::create('semesters', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique();
            $table->string('name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->timestamps();
            $table->index(['start_date', 'end_date']);
            // KHÔNG có is_active
        });
        
        // Seed dữ liệu ngay sau khi tạo bảng
        $this->seedSemesters();
    }
    
    private function seedSemesters(): void {
        $semesters = [
            [
                'code' => '2024-2025 HK1',
                'name' => 'Học kỳ I 2024-2025',
                'start_date' => '2024-09-01',
                'end_date' => '2024-12-31',
            ],
            [
                'code' => '2024-2025 HK2',
                'name' => 'Học kỳ II 2024-2025',
                'start_date' => '2025-01-15',
                'end_date' => '2025-05-31',
            ],
            [
                'code' => '2025-2026 HK1',
                'name' => 'Học kỳ I 2025-2026',
                'start_date' => '2025-09-01',
                'end_date' => '2025-12-31',
            ],
            [
                'code' => '2025-2026 HK2',
                'name' => 'Học kỳ II 2025-2026',
                'start_date' => '2026-01-15',
                'end_date' => '2026-05-31',
            ],
        ];
        
        foreach ($semesters as $semesterData) {
            DB::table('semesters')->insert(array_merge($semesterData, [
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
    }
    
    public function down(): void {
        Schema::dropIfExists('semesters');
    }
};

