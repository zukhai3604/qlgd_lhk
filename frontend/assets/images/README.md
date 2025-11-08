# Hướng dẫn đặt logo

## Vị trí đặt file logo

Đặt file logo của bạn vào thư mục này với tên: **`tlu_logo.png`**

## Yêu cầu về file logo

- **Tên file**: `tlu_logo.png` (hoặc `.jpg`, `.jpeg`)
- **Kích thước khuyến nghị**: 240x240 pixels (hoặc lớn hơn, tỷ lệ 1:1)
- **Định dạng**: PNG (khuyến nghị) hoặc JPG
- **Nền**: Nên có nền trong suốt (PNG) hoặc nền trắng

## Cách đặt logo

1. Copy file logo của bạn vào thư mục này: `frontend/assets/images/tlu_logo.png`
2. Đảm bảo file `pubspec.yaml` đã khai báo thư mục `assets/images/` (đã có sẵn)
3. Chạy lệnh: `flutter pub get` (nếu cần)
4. Chạy lại app để xem logo mới

## Lưu ý

- Nếu không có file logo, app sẽ hiển thị icon mặc định (biểu tượng trường học)
- Logo sẽ được hiển thị trong hình tròn màu xanh đậm
- Logo sẽ tự động scale để vừa với container tròn

