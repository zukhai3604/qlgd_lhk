<?php
// Script để seed semester data trực tiếp
// Chạy: php artisan tinker < seed_semesters_direct.php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

echo "=== SEED SEMESTER DATA ===\n\n";

if (!Schema::hasTable('semesters')) {
    echo "❌ Bảng semesters chưa tồn tại!\n";
    exit(1);
}

$semesters = [
    [
        'code' => '2024-2025 HK1',
        'name' => 'Học kỳ I 2024-2025',
        'start_date' => '2024-09-01',
        'end_date' => '2024-12-31',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'code' => '2024-2025 HK2',
        'name' => 'Học kỳ II 2024-2025',
        'start_date' => '2025-01-15',
        'end_date' => '2025-05-31',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'code' => '2025-2026 HK1',
        'name' => 'Học kỳ I 2025-2026',
        'start_date' => '2025-09-01',
        'end_date' => '2025-12-31',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'code' => '2025-2026 HK2',
        'name' => 'Học kỳ II 2025-2026',
        'start_date' => '2026-01-15',
        'end_date' => '2026-05-31',
        'created_at' => now(),
        'updated_at' => now(),
    ],
];

// Kiểm tra xem có cột is_active không - nếu có thì bỏ qua khi insert
$hasIsActive = Schema::hasColumn('semesters', 'is_active');

$inserted = 0;
$updated = 0;

foreach ($semesters as $semesterData) {
    // Bỏ is_active nếu có
    if ($hasIsActive) {
        unset($semesterData['is_active']);
    }
    
    $exists = DB::table('semesters')->where('code', $semesterData['code'])->exists();
    
    if ($exists) {
        DB::table('semesters')
            ->where('code', $semesterData['code'])
            ->update($semesterData);
        $updated++;
        echo "✓ Updated: {$semesterData['code']}\n";
    } else {
        DB::table('semesters')->insert($semesterData);
        $inserted++;
        echo "✓ Inserted: {$semesterData['code']}\n";
    }
}

echo "\n=== HOÀN THÀNH ===\n";
echo "Inserted: $inserted\n";
echo "Updated: $updated\n";
echo "Total semesters: " . DB::table('semesters')->count() . "\n";

