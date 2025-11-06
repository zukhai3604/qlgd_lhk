<?php
// Script để seed dữ liệu semester trực tiếp
// Chạy trong Docker container: php artisan tinker < seed_semesters.php
// Hoặc copy vào tinker

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

echo "=== SEED SEMESTERS ===\n\n";

if (!Schema::hasTable('semesters')) {
    echo "❌ Bảng semesters chưa tồn tại. Chạy migration trước.\n";
    exit;
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

// Kiểm tra xem có cột is_active không
$hasIsActive = Schema::hasColumn('semesters', 'is_active');
if ($hasIsActive) {
    echo "⚠️  Bảng có cột is_active. Đang bỏ qua cột này khi insert.\n";
    // Bỏ is_active khỏi data nếu có
    foreach ($semesters as &$semester) {
        unset($semester['is_active']);
    }
}

$inserted = 0;
$updated = 0;

foreach ($semesters as $semesterData) {
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
echo "Total: " . DB::table('semesters')->count() . " semester(s)\n";

