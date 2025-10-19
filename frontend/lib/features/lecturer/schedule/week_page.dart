import 'package:flutter/material.dart';
// Nếu bạn muốn điều hướng bằng GoRouter route /schedule/:id thì mở import dưới:
// import 'package:go_router/go_router.dart';
import 'service.dart';
import 'detail_page.dart';

class LecturerWeekPage extends StatefulWidget {
  const LecturerWeekPage({super.key});

  @override
  State<LecturerWeekPage> createState() => _LecturerWeekPageState();
}

class _LecturerWeekPageState extends State<LecturerWeekPage> {
  final _svc = LecturerScheduleService();
  bool loading = true;
  String? error;
  Map<String, dynamic> range = {};
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await _svc.getWeek();
      range = Map<String, dynamic>.from(res['range'] ?? {});
      items = (res['data'] as List)
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color _statusColor(String? s, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (s) {
      case 'TEACHING':
        return cs.primary;
      case 'DONE':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      case 'MAKEUP_PLANNED':
        return Colors.orange;
      case 'MAKEUP_DONE':
        return Colors.teal;
      default:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch giảng dạy')),
        body: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _load,
          child: const Icon(Icons.refresh),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch giảng dạy'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${range['from'] ?? ''} → ${range['to'] ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: items.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Tuần này chưa có buổi học.')),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final it = items[i];
            final status = (it['status'] ?? '') as String;
            return Card(
              child: ListTile(
                title: Text(
                  '${it['subject'] ?? 'Môn'} • ${it['class_name'] ?? 'Lớp'}',
                ),
                subtitle: Text(
                  '${it['date']} | ${it['start_time'] ?? '--:--'}–${it['end_time'] ?? '--:--'}  •  P.${it['room'] ?? '-'}',
                ),
                trailing: Chip(
                  label: Text(status),
                  backgroundColor:
                  _statusColor(status, context).withOpacity(.15),
                ),
                onTap: () {
                  // Nếu bạn đã tạo route /schedule/:id bằng GoRouter:
                  // context.push('/schedule/${it['id']}');

                  // Hoặc mở thẳng widget chi tiết:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LecturerScheduleDetailPage(
                        id: it['id'] as int,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Tải lại'),
      ),
    );
  }
}
