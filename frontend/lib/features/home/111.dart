import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models.dart';

// Tạm stub để compile (sau sẽ thay bằng API thật)
final termProvider = StateProvider<String>((_) => '2025-1');

final meProvider = FutureProvider<User>((ref) async {
  return User(id: 1, name: 'Nguyễn Văn A', email: 'a@tlu.edu.vn', role: 'lecturer');
});

final todayScheduleProvider = FutureProvider<List<ScheduleItem>>((ref) async {
  return <ScheduleItem>[];
});
