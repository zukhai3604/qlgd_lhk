#!/bin/bash

# Test và chạy SystemReportSeeder

echo "=== Checking database connection ==="
php artisan db:show

echo ""
echo "=== Checking users ==="
php artisan tinker --execute="
\$admin = App\Models\User::where('role','ADMIN')->first();
\$lecturers = App\Models\User::where('role','GIANG_VIEN')->count();
echo 'Admin: ' . (\$admin ? \$admin->name : 'NOT FOUND') . PHP_EOL;
echo 'Lecturers: ' . \$lecturers . PHP_EOL;
"

echo ""
echo "=== Running SystemReportSeeder ==="
php artisan db:seed --class=SystemReportSeeder --verbose

echo ""
echo "=== Checking system_reports table ==="
php artisan tinker --execute="
echo 'Total reports: ' . App\Models\SystemReport::count() . PHP_EOL;
"
