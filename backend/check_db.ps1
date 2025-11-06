# Script PowerShell để kiểm tra database schema
# Chạy: .\check_db.ps1

Write-Host "=== KIỂM TRA DATABASE SCHEMA ===" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra đang ở đúng thư mục
if (-not (Test-Path "artisan")) {
    Write-Host "⚠️  Không tìm thấy file artisan. Đang chuyển sang thư mục backend..." -ForegroundColor Yellow
    if (Test-Path "backend\artisan") {
        Set-Location backend
    } else {
        Write-Host "❌ Không tìm thấy thư mục backend hoặc file artisan!" -ForegroundColor Red
        exit 1
    }
}

# Kiểm tra file script
if (-not (Test-Path "check_db_final.php")) {
    Write-Host "⚠️  Không tìm thấy file check_db_final.php" -ForegroundColor Yellow
    Write-Host "   Đang tạo file..." -ForegroundColor Yellow
    # File đã được tạo trước đó
}

Write-Host "📋 Đang kiểm tra database schema..." -ForegroundColor Cyan
Write-Host ""

# Chạy script PHP qua tinker
Get-Content check_db_final.php | php artisan tinker

Write-Host ""
Write-Host "=== HOÀN TẤT ===" -ForegroundColor Green
