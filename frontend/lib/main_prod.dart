import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/app/app.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

void main() {
  Env.init(baseUrl: Env.prodUrl, buildEnv: BuildEnv.prod);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
