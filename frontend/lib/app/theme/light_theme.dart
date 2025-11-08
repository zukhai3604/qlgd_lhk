import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  // Màu xanh đậm cho Trường Đại học Thủy Lợi
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF003366), // Màu xanh đậm
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  // Add other theme properties here
);
