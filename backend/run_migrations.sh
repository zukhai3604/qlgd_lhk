#!/bin/bash
# Script để chạy migrations và seed data trong Docker container
# Chạy: bash run_migrations.sh (trong Docker container)

echo "=== CHẠY MIGRATIONS ==="

# 1. Chạy tất cả migrations chưa chạy
echo "1. Chạy migrations..."
php artisan migrate --force

# 2. Seed semester nếu chưa có
echo "2. Seed semester data..."
php artisan db:seed --class=SemesterSeeder

# 3. Kiểm tra kết quả
echo "3. Kiểm tra kết quả..."
php artisan tinker --execute="
echo 'Semesters: ' . DB::table('semesters')->count() . PHP_EOL;
echo 'Assignments có semester_id: ' . DB::table('assignments')->whereNotNull('semester_id')->count() . PHP_EOL;
echo 'Assignments còn semester_label: ' . DB::table('assignments')->whereNotNull('semester_label')->count() . PHP_EOL;
"

echo "=== HOÀN THÀNH ==="

