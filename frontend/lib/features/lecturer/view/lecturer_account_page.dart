import 'package:flutter/material.dart';

class LecturerAccountPage extends StatelessWidget {
  const LecturerAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This page should not have its own Scaffold.
    // The LecturerBottomNavShell provides it.
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            // Placeholder for an image you will add to your assets
            backgroundImage: AssetImage('assets/images/default_avatar.png'),
            backgroundColor: Colors.black12,
          ),
          SizedBox(height: 16),
          Text('Tài khoản Giảng viên', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Chi tiết tài khoản sẽ được hiển thị ở đây.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
