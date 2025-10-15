// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Sửa đường dẫn LoginPage/LecturerHomePage cho đúng với project của bạn
import 'package:qlgd_lhk/features/auth/view/login_page.dart';
import 'package:qlgd_lhk/features/lecturer/home/lecturer_home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QLGD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1976D2)),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home' : (_) => const LecturerHomePage(),
        // Nếu sau này có:
        // '/admin'   : (_) => const AdminHomePage(),
        // '/training': (_) => const TrainingHomePage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // Tạm thời: có token => vào Home (giảng viên)
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
