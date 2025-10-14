import 'package:flutter/material.dart';

class SchedulePageTraining extends StatelessWidget {
  const SchedulePageTraining({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Schedule')),
      body: const Center(child: Text('Schedule content for Training')),
    );
  }
}
