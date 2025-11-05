// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view_model/leave_view_model.dart';
import 'package:qlgd_lhk/features/lecturer/leave/utils/leave_data_helpers.dart';

class LeavePage extends ConsumerStatefulWidget {
  const LeavePage({super.key, required this.session});
  final Map<String, dynamic> session;

  @override
  ConsumerState<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends ConsumerState<LeavePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final leaveViewModel = ref.read(leaveViewModelProvider(widget.session).notifier);
    final success = await leaveViewModel.submitLeaveRequest(_reasonController.text.trim());

    if (!mounted) return;

    if (success) {
      // Chuyển thẳng đến history
      context.go('/leave/history');
    } else {
      // Hiển thị lỗi từ state
      final state = ref.read(leaveViewModelProvider(widget.session));
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    }
  }

  String _dateVN(String yyyyMmDd) {
    if (yyyyMmDd.isEmpty) return '';
    try {
      final dt = DateTime.parse(yyyyMmDd);
      return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dt);
    } catch (_) {
      final p = yyyyMmDd.split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
      return yyyyMmDd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveViewModelProvider(widget.session));
    final s = widget.session;

    // Sử dụng helper classes để extract data
    final subjectInline = LeaveDataExtractor.extractSubject(s);
    final subject = (subjectInline.isNotEmpty && subjectInline != 'Môn học')
        ? subjectInline
        : (leaveState.subject ?? subjectInline);

    final className = LeaveDataExtractor.extractClassName(s);
    final cohort = LeaveDataExtractor.extractCohort(s);
    final roomInline = LeaveDataExtractor.extractRoom(s);
    final room = roomInline.isNotEmpty ? roomInline : (leaveState.room ?? '');

    final dateIso = LeaveDataExtractor.extractDate(s);
    final dateLabel = _dateVN(dateIso);
    final time = LeaveDataExtractor.extractTime(s);
    final start = time.startTime;
    final end = time.endTime;

    final classLineParts = <String>[
      'Lớp: $className${cohort.isNotEmpty ? ' - $cohort' : ''}',
      if (room.isNotEmpty) 'Phòng: $room',
      if (leaveState.isLoading && (roomInline.isEmpty || subjectInline.isEmpty || subjectInline == 'Môn học'))
        'đang tải thông tin…',
    ];
    final classLine = classLineParts.join(' • ');

    return Scaffold(
      appBar: const TluAppBar(title: 'Đơn xin nghỉ'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card thông tin buổi học
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Môn học với icon sách
                    Row(
                      children: [
                        Icon(Icons.book, size: 18, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subject,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Lớp và Phòng với icon calendar
                    if (classLine.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(classLine),
                          ),
                        ],
                      ),
                    if (classLine.isNotEmpty) const SizedBox(height: 6),
                    // Ngày và giờ với icon clock
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('$dateLabel • $start - $end'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Form lý do
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Lý do xin nghỉ',
                hintText: 'Nhập lý do (tối thiểu 10 ký tự)',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 10) return 'Lý do quá ngắn (tối thiểu 10 ký tự)';
                if (t.length > 500) return 'Lý do quá dài (tối đa 500 ký tự)';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: leaveState.isSubmitting ? null : _submit,
              icon: leaveState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Gửi đơn'),
            ),
          ),
        ],
      ),
    );
  }
}
