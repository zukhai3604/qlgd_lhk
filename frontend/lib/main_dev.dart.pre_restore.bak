import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/app/app.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lấy BASE_URL từ --dart-define (nếu không truyền thì dùng mặc định cho Android emulator)
  const fallback = 'http://10.0.2.2:8888';
  const defined  = String.fromEnvironment('BASE_URL', defaultValue: fallback);

  Env.init(
    overrideBaseUrl: defined,
    overrideBuildEnv: BuildEnv.dev,
  );

  runApp(const ProviderScope(child: App()));
}
