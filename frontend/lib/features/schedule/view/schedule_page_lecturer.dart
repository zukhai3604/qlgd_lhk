import 'package:flutter/material.dart';

class SchedulePageLecturer extends StatelessWidget {
  const SchedulePageLecturer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecturer Schedule')),
      body: const Center(child: Text('Schedule content for Lecturer')),
    );
  }
}
