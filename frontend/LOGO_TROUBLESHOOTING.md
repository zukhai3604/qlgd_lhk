# Hướng dẫn khắc phục logo không hiển thị

## Đã kiểm tra:
✅ File logo tồn tại tại: `assets/images/tlu_logo.png`
✅ `pubspec.yaml` đã khai báo `assets/images/`
✅ Code đã sử dụng đúng đường dẫn: `assets/images/tlu_logo.png`
✅ Theme đã được cập nhật với màu xanh đậm

## Các bước khắc phục:

### 1. Rebuild app (QUAN TRỌNG!)
Sau khi thêm asset mới, bạn **PHẢI** rebuild app:

```bash
# Dừng app hiện tại (nếu đang chạy)
# Sau đó chạy một trong các lệnh sau:

# Cách 1: Clean và rebuild
flutter clean
flutter pub get
flutter run

# Cách 2: Hot restart không đủ, cần full rebuild
# Trong VS Code/Android Studio: Stop app hoàn toàn, rồi Run lại
```

### 2. Kiểm tra console/debug
- Mở Debug Console trong VS Code/Android Studio
- Tìm dòng log: `Logo load error: ...` (nếu có lỗi)
- Nếu thấy icon mặc định (biểu tượng trường học) thay vì logo, có nghĩa là asset chưa được load

### 3. Kiểm tra file logo
- Đảm bảo file có tên chính xác: `tlu_logo.png` (không phải `TLU_logo.png` hay `tlu_logo.PNG`)
- Đảm bảo file không bị corrupt
- Kích thước khuyến nghị: 240x240 pixels hoặc lớn hơn

### 4. Nếu vẫn không hiển thị
Thử thay đổi cách load asset trong code:

```dart
// Thay vì AssetImage, thử dùng:
Image.asset('assets/images/tlu_logo.png')
```

### 5. Kiểm tra build folder
Xóa build folder và rebuild:
```bash
flutter clean
rm -rf build/  # hoặc xóa thủ công
flutter pub get
flutter run
```

## Lưu ý:
- **Hot reload (r) KHÔNG đủ** để load asset mới, cần **full rebuild**
- Asset chỉ được bundle vào app khi build, không phải khi hot reload
- Nếu đang chạy trên device/emulator, cần stop app hoàn toàn và chạy lại

