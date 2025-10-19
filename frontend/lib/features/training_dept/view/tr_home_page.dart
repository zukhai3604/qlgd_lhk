import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrainingDepartmentHomePage extends StatelessWidget {
  const TrainingDepartmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Đơn nghỉ & dạy bù', '/training-dept/requests', Icons.assignment),
      ('Báo cáo học kỳ',     '/training-dept/reports',  Icons.insights),
      ('Lịch tuần / tháng',  '/training-dept/schedule', Icons.calendar_month),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng Đào tạo — Home')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: Icon(items[i].$3),
          title: Text(items[i].$1),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(items[i].$2),
        ),
      ),
    );
  }
}
