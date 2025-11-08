import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  // Màu xanh đậm cho Trường Đại học Thủy Lợi
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF003366), // Màu xanh đậm
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  // Add other theme properties here
);
