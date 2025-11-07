import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LecturerBottomNavShell extends StatefulWidget {
  final Widget child;
  const LecturerBottomNavShell({super.key, required this.child});

  @override
  State<LecturerBottomNavShell> createState() => _LecturerBottomNavShellState();
}

class _LecturerBottomNavShellState extends State<LecturerBottomNavShell> {
  // Đổi tên đường dẫn giữa các tab nếu cần
  static const _tabs = ['/home', '/notifications', '/account'];

  int _computeIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(_tabs[1])) return 1;
    if (location.startsWith(_tabs[2])) return 2;
    return 0;
  }

  void _onTap(int index) {
    if (index < 0 || index >= _tabs.length) return;
    final target = _tabs[index];
    // Ngăn chuyển tab trùng
    if (GoRouterState.of(context).uri.toString().startsWith(target)) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _computeIndex(context),
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
