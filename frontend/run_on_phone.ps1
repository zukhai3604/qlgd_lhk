# Script để chạy Flutter app trên điện thoại thật
# IP máy tính: 192.168.26.103
# Port backend: 8888

$BASE_URL = "http://192.168.26.103:8888"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Chạy Flutter App trên Điện Thoại Thật" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IP máy tính: 192.168.26.103" -ForegroundColor Yellow
Write-Host "Backend URL: $BASE_URL" -ForegroundColor Yellow
Write-Host ""

# Kiểm tra thiết bị
Write-Host "Đang kiểm tra thiết bị đã kết nối..." -ForegroundColor Green
flutter devices

Write-Host ""
Write-Host "Đang khởi động app với BASE_URL=$BASE_URL..." -ForegroundColor Green
Write-Host ""

# Chạy app với BASE_URL
flutter run --dart-define=BASE_URL=$BASE_URL

