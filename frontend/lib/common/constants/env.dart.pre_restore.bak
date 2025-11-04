import 'package:flutter/foundation.dart';

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
  /// web -> http://127.0.0.1:8888, mobile -> http://10.0.2.2:8888
  static void init({String? overrideBaseUrl, BuildEnv? overrideBuildEnv}) {
    final env = overrideBuildEnv ?? _parseBuildEnv(_definedBuildEnv);
    final fallback = kIsWeb
        ? _fallbackForWeb()
        : 'http://10.0.2.2:8888'; // Emulator default, override via --dart-define when cần

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
}

extension _NullOrEmpty on String? {
  bool get isNotEmptyOrNull => this != null && this!.isNotEmpty;
}
