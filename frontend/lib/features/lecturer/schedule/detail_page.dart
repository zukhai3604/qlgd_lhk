// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _pickAndUploadFile() async {
    try {
      // Chọn file (PDF, PPT, Word)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Hiển thị dialog để nhập title
      final title = await showDialog<String>(
        context: context,
        builder: (context) {
          final titleCtrl = TextEditingController();
          return AlertDialog(
            title: const Text('Thêm tài liệu'),
            content: TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên tài liệu',
                hintText: 'Ví dụ: Bài giảng chương 1',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isNotEmpty) {
                    Navigator.pop(context, title);
                  }
                },
                child: const Text('Upload'),
              ),
            ],
          );
        },
      );

      if (title == null || title.isEmpty) return;

      // Upload file
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang upload file...')),
      );

      // Xác định file type
      final extension = file.extension?.toLowerCase() ?? '';
      String? fileType;
      if (extension == 'pdf') {
        fileType = 'application/pdf';
      } else if (extension == 'ppt' || extension == 'pptx') {
        fileType = 'application/vnd.ms-powerpoint';
      } else if (extension == 'doc' || extension == 'docx') {
        fileType = 'application/msword';
      }

      await _svc.uploadMaterialFile(
        sessionId: widget.sessionId,
        title: title,
        filePath: file.path!,
        fileType: fileType,
      );

      // Reload materials
      final m = await _svc.getMaterials(widget.sessionId);
      if (!mounted) return;
      setState(() => _materials = m);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã upload tài liệu thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
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
                        onPressed: () {
                          // Kiểm tra xem có _grouped_session_ids không (buổi học đã được gộp)
                          final groupedIds = widget.sessionData?['_grouped_session_ids'] as List?;
                          
                          context.push(
                            '/attendance/${widget.sessionId}',
                            extra: {
                              'subjectName': subject,
                              'className': className,
                              'groupedSessionIds': groupedIds, // Truyền danh sách session IDs đã gộp
                            },
                          );
                        },
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
                          fileType: (m['file_type'] ?? '').toString(),
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
                        IconButton(
                          onPressed: _pickAndUploadFile,
                          icon: const Icon(Icons.upload_file),
                          tooltip: 'Upload file (PDF, PPT, Word)',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                '$k:',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(v),
            ),
          ],
        ),
      );

  Widget _materialTile(
    ThemeData theme, {
    required String title,
    String? subtitle,
    String? url,
    String? fileType,
    bool disabled = false,
  }) {
    final hasUrl = (url ?? '').isNotEmpty;
    
    // Xác định icon dựa trên file type
    IconData iconData = Icons.description_outlined;
    Color? iconColor;
    
    if (fileType != null && fileType.isNotEmpty) {
      if (fileType.contains('pdf')) {
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
      } else if (fileType.contains('powerpoint') || fileType.contains('presentation')) {
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
      } else if (fileType.contains('word') || fileType.contains('msword')) {
        iconData = Icons.description;
        iconColor = Colors.blue;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        enabled: !disabled,
        leading: Icon(iconData, color: iconColor),
        title: Text(title),
        subtitle:
            (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
        trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
        onTap: hasUrl
            ? () async {
                // Mở file trong browser hoặc app phù hợp
                final uri = Uri.parse(url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể mở file')),
                  );
                }
              }
            : null,
        dense: true,
      ),
    );
  }
}
