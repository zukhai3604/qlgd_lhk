import 'package:flutter/material.dart';

// Đúng đường dẫn file trang giảng viên của bạn
import '../features/lecturer/home/lecturer_home_page.dart';
// Đúng đường dẫn login
import '../features/auth/view/login_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QLGD LHK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1976D2)),
      home: const LoginPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home' : (_) => const LecturerHomePage(),
      },
    );
  }
}
