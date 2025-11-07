// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';

class LecturerReportPage extends StatelessWidget {
  const LecturerReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo chi tiết')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            ReportRow(subject: 'Công nghệ Web', done: 16, total: 30),
            ReportRow(subject: 'Nền tảng Web', done: 12, total: 30),
            ReportRow(subject: 'Mobile Dev', done: 15, total: 30),
          ],
        ),
      ),
    );
  }
}

class ReportRow extends StatelessWidget {
  final String subject;
  final int done;
  final int total;
  const ReportRow(
      {required this.subject, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$subject ($done/$total buổi)'),
          LinearProgressIndicator(value: ratio),
        ],
      ),
    );
  }
}
