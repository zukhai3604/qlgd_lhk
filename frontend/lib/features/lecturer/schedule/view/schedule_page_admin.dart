import 'package:flutter/material.dart';

class SchedulePageAdmin extends StatelessWidget {
  const SchedulePageAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Schedule')),
      body: const Center(child: Text('Schedule content for Admin')),
    );
  }
}
