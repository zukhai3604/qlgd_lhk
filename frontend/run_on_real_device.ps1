# Script chạy Flutter app trên điện thoại thật (Pixel 6)
# Backend URL: http://192.168.26.103:8888

$DEVICE_ID = "25261FDF6008QP"
$BASE_URL = "http://192.168.26.103:8888"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Chạy App Flutter trên Máy Thật" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Thiết bị: Pixel 6 ($DEVICE_ID)" -ForegroundColor Yellow
Write-Host "Backend URL: $BASE_URL" -ForegroundColor Yellow
Write-Host ""

# Kiểm tra thiết bị
Write-Host "Đang kiểm tra thiết bị..." -ForegroundColor Green
flutter devices

Write-Host ""
Write-Host "Đang build và chạy app..." -ForegroundColor Green
Write-Host ""

# Chạy app với BASE_URL cho máy thật
flutter run -d $DEVICE_ID --dart-define=BASE_URL=$BASE_URL

