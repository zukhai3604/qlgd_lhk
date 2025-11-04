import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qlgd_lhk/app/app.dart';
import 'package:qlgd_lhk/common/constants/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.init();

  await initializeDateFormatting('vi');
  await initializeDateFormatting('en');

  runApp(const ProviderScope(child: App()));
}
