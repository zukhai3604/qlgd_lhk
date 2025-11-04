// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'service.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';

class LecturerScheduleDetailPage extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic>? sessionData; // Session data đã gộp từ home page
  
  const LecturerScheduleDetailPage({
    super.key,
    required this.sessionId,
    this.sessionData,
  });

  @override
  State<LecturerScheduleDetailPage> createState() =>
      _LecturerScheduleDetailPageState();
}

class _LecturerScheduleDetailPageState
    extends State<LecturerScheduleDetailPage> {
  final _svc = LecturerScheduleService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _detail = {};
  List<Map<String, dynamic>> _materials = [];

  final TextEditingController _newMaterialCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  String _statusValue = 'done';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newMaterialCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _svc.getDetail(widget.sessionId);
      final m = await _svc.getMaterials(widget.sessionId);

      final rawStatus = (d['status'] ?? '').toString().toLowerCase();
      _statusValue = switch (rawStatus) {
        'done' => 'done',
        'teaching' => 'teaching',
        'canceled' || 'cancelled' => 'canceled',
        _ => 'done',
      };

      _detail = d;
      _materials = m;

      final note = (d['note'] ?? '').toString();
      if (note.isNotEmpty) _noteCtrl.text = note;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _hhmm(dynamic s) {
    final str = (s ?? '').toString();
    return str.length >= 5 ? str.substring(0, 5) : str;
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Future<void> _addMaterial() async {
    final title = _newMaterialCtrl.text.trim();
    if (title.isEmpty) return;
    await _svc.addMaterial(widget.sessionId, title);
    _newMaterialCtrl.clear();
    final m = await _svc.getMaterials(widget.sessionId);
    if (!mounted) return;
    setState(() => _materials = m);
  }

  Future<void> _saveReport() async {
    await _svc.submitReport(
      sessionId: widget.sessionId,
      status: _statusValue,
      note: _noteCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu báo cáo buổi học')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: const TluAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: const TluAppBar(),
        body: Center(
          child: Text(
            'Không tải được dữ liệu.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // ===== Normalize fields for display =====
    // Subject/Class
    final subjVal = _detail['subject'];
    final asg = _detail['assignment'];
    final subjMap = (subjVal is Map)
        ? subjVal
        : (asg is Map && asg['subject'] is Map ? asg['subject'] : null);
    final subject = (subjMap is Map
            ? (subjMap['name'] ?? subjMap['code'])
            : (subjVal ?? ''))
        .toString();

    final cuVal = _detail['class_unit'] ?? _detail['class'];
    final cuMap = (cuVal is Map)
        ? cuVal
        : (asg is Map && asg['classUnit'] is Map ? asg['classUnit'] : null);
    final className = (cuMap is Map
            ? (cuMap['name'] ?? cuMap['code'])
            : (_detail['class_name'] ?? ''))
        .toString();

    // Date
    final rawDate = ((_detail['date'] ??
                _detail['session_date'] ??
                _detail['sessionDate']) ??
            '')
        .toString();
    final dateOnly = rawDate.contains(' ') ? rawDate.split(' ').first : rawDate;
    final date = _fmtDate(dateOnly);

    // Time - Nếu có sessionData đã gộp từ home page, ưu tiên dùng thời gian đã gộp
    String start = '';
    String end = '';
    
    if (widget.sessionData != null) {
      // Nếu có session data đã gộp, dùng thời gian đã gộp (cả buổi)
      final mergedStart = widget.sessionData!['start_time'];
      final mergedEnd = widget.sessionData!['end_time'];
      if (mergedStart != null) start = _hhmm(mergedStart);
      if (mergedEnd != null) end = _hhmm(mergedEnd);
    }
    
    // Nếu không có hoặc thiếu, lấy từ detail API (cho trường hợp load trực tiếp từ URL)
    if (start.isEmpty || end.isEmpty) {
      final ts = _detail['timeslot'];
      start = _hhmm(_detail['start_time'] ??
          _detail['start'] ??
          (ts is Map ? ts['start_time'] : null));
      end = _hhmm(_detail['end_time'] ??
          _detail['end'] ??
          (ts is Map ? ts['end_time'] : null));
    }

    // Room
    final r = _detail['room'];
    final room = (r is Map
            ? (r['name']?.toString() ?? r['code']?.toString() ?? '')
            : r?.toString() ?? '')
        .trim();

    return Scaffold(
      appBar: const TluAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Text(
                      '$subject - $className',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text('Điểm danh sinh viên'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _kv('Ca',
                        (start.isEmpty && end.isEmpty) ? '-' : '$start - $end'),
                    _kv('Ngày', date.isEmpty ? '-' : date),
                    _kv('Phòng', room.isEmpty ? '-' : room),
                    const SizedBox(height: 12),
                    Text(
                      'Nội dung bài học',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_materials.isEmpty)
                      _materialTile(
                        theme,
                        title: 'Chưa có nội dung',
                        disabled: true,
                      )
                    else
                      ..._materials.map(
                        (m) => _materialTile(
                          theme,
                          title: (m['title'] ?? '').toString(),
                          subtitle: (m['uploaded_at'] ?? '').toString(),
                          url: (m['file_url'] ?? '').toString(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newMaterialCtrl,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.add),
                              hintText: 'Thêm nội dung bài học',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addMaterial,
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusValue,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái giảng dạy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'done',
                          child: Text('Đã hoàn thành'),
                        ),
                        DropdownMenuItem(
                          value: 'teaching',
                          child: Text('Đang dạy'),
                        ),
                        DropdownMenuItem(
                          value: 'canceled',
                          child: Text('Hủy buổi'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _statusValue = v ?? 'done'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveReport,
                  child: const Text('Lưu'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 145,
              child: Text(
                '$k:',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _materialTile(
    ThemeData theme, {
    required String title,
    String? subtitle,
    String? url,
    bool disabled = false,
  }) {
    final hasUrl = (url ?? '').isNotEmpty;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        enabled: !disabled,
        leading: const Icon(Icons.description_outlined),
        title: Text(title),
        subtitle:
            (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
        trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
        onTap: hasUrl ? () {} : null,
        dense: true,
      ),
    );
  }
}
