// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../schedule/service.dart';

class LecturerChooseSessionPage extends StatefulWidget {
  const LecturerChooseSessionPage({super.key});

  @override
  State<LecturerChooseSessionPage> createState() =>
      _LecturerChooseSessionPageState();
}

class _LecturerChooseSessionPageState extends State<LecturerChooseSessionPage> {
  final _scheduleSvc = LecturerScheduleService();

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await _scheduleSvc.getWeek();
      final all = (res['data'] as List? ?? const [])
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final today = DateTime.now().toIso8601String().substring(0, 10);

      // chỉ lấy các buổi còn kế hoạch & từ hôm nay trở đi
      sessions = all.where((s) {
        final isPlanned = (s['status']?.toString().toUpperCase() == 'PLANNED');
        final d = (s['date'] ?? '') as String;
        final notPending = (s['leave_status'] ?? '') != 'PENDING';
        return isPlanned && d.compareTo(today) >= 0 && notPending;
      }).toList();
    } catch (e) {
      error = 'Không tải được danh sách buổi dạy: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        centerTitle: true,
        title: Text(
          'TRƯỜNG ĐẠI HỌC THỦY LỢI',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: .2,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorBox(message: error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Chọn buổi cần nghỉ',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      if (sessions.isEmpty)
                        _EmptyBox(onReload: _load)
                      else
                        ...sessions.map((s) => _SessionCard(
                              subject: s['subject'] ?? 'Môn học',
                              dateText: _dateLine(
                                s['date'],
                                s['start_time'],
                                s['end_time'],
                                s['room'],
                              ),
                              onTap: () =>
                                  context.push('/leave/form', extra: s),
                              borderColor: cs.outlineVariant,
                            )),
                    ],
                  ),
                ),
    );
  }

  String _dateLine(String? d, String? start, String? end, String? roomCode) {
    String thu = '';
    String ddMMyyyy = '';
    try {
      if ((d ?? '').length >= 10) {
        final dt = DateTime.parse(d!);
        const mapThu = {
          1: 'Thứ 2',
          2: 'Thứ 3',
          3: 'Thứ 4',
          4: 'Thứ 5',
          5: 'Thứ 6',
          6: 'Thứ 7',
          7: 'Chủ nhật',
        };
        thu = mapThu[dt.weekday] ?? '';
        ddMMyyyy =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (_) {}

    final time = '${start ?? '--:--'} - ${end ?? '--:--'}';
    final room = roomCode == null || roomCode.toString().isEmpty
        ? ''
        : ' · ${roomCode.toString()}';
    return [thu, ddMMyyyy, time].where((x) => x.isNotEmpty).join(' · ') + room;
  }
}

class _SessionCard extends StatelessWidget {
  final String subject;
  final String dateText;
  final VoidCallback onTap;
  final Color borderColor;

  const _SessionCard({
    required this.subject,
    required this.dateText,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor.withOpacity(.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                dateText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          )
        ]),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final VoidCallback onReload;
  const _EmptyBox({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available, size: 56, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('Không có buổi học nào sắp tới để xin nghỉ.',
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}
