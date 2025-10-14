import 'package:flutter/foundation.dart';

class AppEnv {
  static String get baseUrl {
    return kIsWeb ? 'http://127.0.0.1:8888' : 'http://10.0.2.2:8888';
  }
}
