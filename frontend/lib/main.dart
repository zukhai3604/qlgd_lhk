import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/app/app.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // CÁCH A: dùng fallback 8888 đã cấu hình trong Env.init()
  Env.init();

  // CÁCH B (tuỳ chọn): ép về 8888 rõ ràng
  // Env.init(
  //   overrideBaseUrl: kIsWeb ? 'http://127.0.0.1:8888' : 'http://10.0.2.2:8888',
  //   overrideBuildEnv: BuildEnv.dev,
  // );

  runApp(const ProviderScope(child: App()));
}
