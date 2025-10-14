import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/app/app.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

void main() {
  // Default to the development environment when running main.dart directly
  Env.init(baseUrl: Env.devUrl, buildEnv: BuildEnv.dev);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
