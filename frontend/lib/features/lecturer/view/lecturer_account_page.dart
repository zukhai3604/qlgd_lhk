import 'package:flutter/material.dart';

class LecturerAccountPage extends StatelessWidget {
  const LecturerAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản Giảng viên')),
      body: const Center(
        child: Text('Chi tiết tài khoản của giảng viên sẽ được hiển thị ở đây.'),
      ),
    );
  }
}
