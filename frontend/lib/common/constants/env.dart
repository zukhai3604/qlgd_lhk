import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

enum BuildEnv { dev, stg, prod }

class Env {
  Env._();

  static late String baseUrl;
  static late BuildEnv buildEnv;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  // Đọc từ --dart-define (nếu có)
  static const String _definedBaseUrl = String.fromEnvironment('BASE_URL');
  static const String _definedBuildEnv =
      String.fromEnvironment('BUILD_ENV', defaultValue: 'dev');

  /// Nếu không truyền tham số, tự đọc --dart-define; nếu thiếu thì fallback:
  /// web -> http://127.0.0.1:8888
  /// mobile emulator -> http://10.0.2.2:8888
  /// mobile real device -> http://192.168.1.100:8888 (thay IP thật của máy bạn)
  static void init({String? overrideBaseUrl, BuildEnv? overrideBuildEnv}) {
    final env = overrideBuildEnv ?? _parseBuildEnv(_definedBuildEnv);
    
    // Tự động phát hiện môi trường và sử dụng URL phù hợp
    final fallback = kIsWeb
        ? _fallbackForWeb()
        : _fallbackForMobile();

    final rawBase = overrideBaseUrl.isNotEmptyOrNull
        ? overrideBaseUrl!
        : (_definedBaseUrl.isNotEmpty ? _definedBaseUrl : fallback);

    // chuẩn hoá: bỏ dấu / cuối cùng (nếu có)
    final normalized = rawBase.endsWith('/')
        ? rawBase.substring(0, rawBase.length - 1)
        : rawBase;

    baseUrl = normalized;
    buildEnv = env;
    _isInitialized = true;

    if (kDebugMode) {
      print('🌐 API Base URL: $baseUrl');
      print('📱 Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    }
  }

  static BuildEnv _parseBuildEnv(String v) {
    switch (v.toLowerCase()) {
      case 'prod':
        return BuildEnv.prod;
      case 'stg':
        return BuildEnv.stg;
      default:
        return BuildEnv.dev;
    }
  }

  static String _fallbackForWeb() {
    final uri = Uri.base;
    final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'http';
    final host = uri.host.isNotEmpty ? uri.host : '127.0.0.1';
    final port = 8888;
    return '$scheme://$host:$port';
  }

  static String _fallbackForMobile() {
    // ⚠️ QUAN TRỌNG: Chọn IP phù hợp với thiết bị của bạn
    //
    // 🖥️ Android Emulator: Sử dụng 10.0.2.2
    // 📱 Điện thoại thật + USB + adb reverse: Sử dụng 127.0.0.1
    // 📱 Điện thoại thật + Wi-Fi: Sử dụng IP thật của máy tính (192.168.1.14)
    //
    // Để kiểm tra IP máy tính: mở CMD và gõ lệnh "ipconfig"
    // Tìm dòng "IPv4 Address" trong phần "Wireless LAN adapter Wi-Fi"

    const useRealDevice = true; // Đổi thành true nếu test trên điện thoại thật
    const useAdbReverse = true; // ✅ ĐANG DÙNG ADB REVERSE (USB debugging)
    const realDeviceIp = '192.168.1.14'; // IP thật của máy tính bạn (nếu dùng Wi-Fi)

    if (!kIsWeb && Platform.isAndroid) {
      if (useRealDevice) {
        if (useAdbReverse) {
          return 'http://127.0.0.1:8888'; // ✅ Qua adb reverse
        }
        return 'http://$realDeviceIp:8888'; // Điện thoại thật qua Wi-Fi
      }
      return 'http://10.0.2.2:8888'; // Android Emulator
    }
    // iOS Simulator có thể dùng localhost trực tiếp
    if (!kIsWeb && Platform.isIOS) {
      return 'http://127.0.0.1:8888';
    }
    // Fallback cho các trường hợp khác
    return 'http://127.0.0.1:8888';
  }
}

extension _NullOrEmpty on String? {
  bool get isNotEmptyOrNull => this != null && this!.isNotEmpty;
}
