import 'package:flutter/material.dart';
import 'service.dart';

class LecturerScheduleDetailPage extends StatefulWidget {
  final int id;
  const LecturerScheduleDetailPage({super.key, required this.id});

  @override
  State<LecturerScheduleDetailPage> createState() => _LecturerScheduleDetailPageState();
}

class _LecturerScheduleDetailPageState extends State<LecturerScheduleDetailPage> {
  final _svc = LecturerScheduleService();
  bool loading = true;
  String? error;
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> materials = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      data = await _svc.getDetail(widget.id);
      materials = await _svc.listMaterials(widget.id);
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitReport() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nộp báo cáo buổi học'),
        content: TextField(
          controller: ctrl, maxLines: 5,
          decoration: const InputDecoration(hintText: 'Nội dung báo cáo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gửi')),
        ],
      ),
    );
    if (ok != true) return;

    await _svc.submitReport(widget.id, content: ctrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nộp báo cáo')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết buổi học')),
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết buổi học')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${data['subject']} • ${data['class_name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${data['date']} | ${data['start_time']}–${data['end_time']} • Phòng ${data['room'] ?? '-'}'),
            const SizedBox(height: 8),
            Chip(label: Text(data['status'] ?? 'PLANNED')),
            if ((data['note'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Ghi chú: ${data['note']}', style: const TextStyle(color: Colors.black54)),
            ],
            const Divider(height: 24),

            const Text('Tài liệu', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (materials.isEmpty) const Text('Chưa có tài liệu.'),
            for (final m in materials)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(m['title'] ?? ''),
                  subtitle: Text('${m['created_at'] ?? ''}'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // TODO: mở url với url_launcher
                    // launchUrlString(m['url']);
                  },
                ),
              ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Nộp báo cáo buổi học'),
            ),
          ],
        ),
      ),
    );
  }
}
