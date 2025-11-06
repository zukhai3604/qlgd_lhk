# Script PowerShell để kiểm tra và xóa cột is_active từ bảng semesters
# Chạy: .\fix_semesters_is_active.ps1

Write-Host "=== KIỂM TRA VÀ XÓA CỘT is_active TRONG BẢNG semesters ===" -ForegroundColor Cyan
Write-Host ""

# Chuyển vào thư mục backend
Set-Location "projectcuoiki\backend"

# Cách 1: Chạy migration mới để xóa is_active
Write-Host "Cách 1: Chạy migration mới để xóa is_active..." -ForegroundColor Yellow
php artisan migrate --path=database/migrations/2025_11_06_000000_remove_is_active_from_semesters_final.php

Write-Host ""
Write-Host "Cách 2: Chạy script PHP trực tiếp..." -ForegroundColor Yellow
php artisan tinker < fix_semesters_is_active.php

Write-Host ""
Write-Host "=== KIỂM TRA KẾT QUẢ ===" -ForegroundColor Cyan
Write-Host "Đang kiểm tra xem cột is_active còn tồn tại không..."

# Kiểm tra bằng tinker
php artisan tinker --execute="
use Illuminate\Support\Facades\Schema;
if (Schema::hasColumn('semesters', 'is_active')) {
    echo '❌ VẪN CÒN: Bảng semesters vẫn có cột is_active!' . PHP_EOL;
    exit(1);
} else {
    echo '✓ OK: Bảng semesters KHÔNG có cột is_active!' . PHP_EOL;
    exit(0);
}
"

Write-Host ""
Write-Host "Hoàn thành!" -ForegroundColor Green

