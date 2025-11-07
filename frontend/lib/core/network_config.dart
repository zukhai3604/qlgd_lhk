// filepath: lib/core/network_config.dart
// File chứa cấu hình mạng (base URL) để dễ sửa khi chạy trên emulator / device

class NetworkConfig {
  // ĐANG DÙNG ADB REVERSE - điện thoại cắm USB
  // Thay đổi giá trị này nếu bạn chạy backend trên máy khác.
  // Ví dụ:
  // - USB debugging + adb reverse: "http://127.0.0.1:8888" ✅ ĐANG DÙNG
  // - Android emulator (default AVD): "http://10.0.2.2:8888"
  // - Genymotion emulator: "http://10.0.3.2:8888"
  // - Physical device on same LAN: "http://192.168.1.14:8888"

  static const String apiBaseUrl = 'http://127.0.0.1:8888'; // qua adb reverse
}
