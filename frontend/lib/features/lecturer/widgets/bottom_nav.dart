import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        // Avoid unnecessary navigation
        if (currentIndex == i) return;

        if (i == 0) {
          context.go('/home');
        } else if (i == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thông báo: đang phát triển')),
          );
        } else if (i == 2) {
          context.go('/account');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Thông báo',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
