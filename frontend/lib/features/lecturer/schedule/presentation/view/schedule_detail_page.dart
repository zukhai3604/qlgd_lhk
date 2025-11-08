// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/presentation/view_model/schedule_detail_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturerScheduleDetailPage extends ConsumerStatefulWidget {
  final int sessionId;
  final Map<String, dynamic>? sessionData;
  
  const LecturerScheduleDetailPage({
    super.key,
    required this.sessionId,
    this.sessionData,
  });

  @override
  ConsumerState<LecturerScheduleDetailPage> createState() => _LecturerScheduleDetailPageState();
}

class _LecturerScheduleDetailPageState extends ConsumerState<LecturerScheduleDetailPage> {
  final TextEditingController _newMaterialCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _statusCtrl = TextEditingController();
  String? _lastSyncedNote; // Track last synced note value

  @override
  void dispose() {
    _newMaterialCtrl.dispose();
    _noteCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleDetailViewModelProvider(widget.sessionId));
    final viewModel = ref.read(scheduleDetailViewModelProvider(widget.sessionId).notifier);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: const TluAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Scaffold(
        appBar: const TluAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Không tải được dữ liệu.\n${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => viewModel.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = state.detail ?? {};
    final materials = state.materials;

    // ===== Normalize fields for display =====
    // Subject/Class
    final subjVal = detail['subject'];
    final asg = detail['assignment'];
    final subjMap = (subjVal is Map)
        ? subjVal
        : (asg is Map && asg['subject'] is Map ? asg['subject'] : null);
    final subject = (subjMap is Map
            ? (subjMap['name'] ?? subjMap['code'])
            : (subjVal ?? ''))
        .toString();

    final cuVal = detail['class_unit'] ?? detail['class'];
    final cuMap = (cuVal is Map)
        ? cuVal
        : (asg is Map && asg['classUnit'] is Map ? asg['classUnit'] : null);
    final className = (cuMap is Map
            ? (cuMap['name'] ?? cuMap['code'])
            : (detail['class_name'] ?? ''))
        .toString();

    // Date
    final rawDate = ((detail['date'] ??
                detail['session_date'] ??
                detail['sessionDate']) ??
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
      final ts = detail['timeslot'];
      start = _hhmm(detail['start_time'] ??
          detail['start'] ??
          (ts is Map ? ts['start_time'] : null));
      end = _hhmm(detail['end_time'] ??
          detail['end'] ??
          (ts is Map ? ts['end_time'] : null));
    }

    // Room
    final r = detail['room'];
    final room = (r is Map
            ? (r['name']?.toString() ?? r['code']?.toString() ?? '')
            : r?.toString() ?? '')
        .trim();

    // Sync note controller với state (chỉ khi state thay đổi từ backend, không overwrite user input)
    // Chỉ sync khi:
    // 1. state.note thay đổi từ backend (khác với _lastSyncedNote)
    // 2. VÀ TextField rỗng hoặc TextField khớp với giá trị cũ đã sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Nếu state.note thay đổi từ backend (khác với giá trị đã sync trước đó)
      if (state.note != _lastSyncedNote) {
        // Chỉ sync nếu TextField rỗng hoặc TextField đang hiển thị giá trị cũ đã sync
        // HOẶC nếu _lastSyncedNote là null (lần đầu load)
        if (_noteCtrl.text.isEmpty || _noteCtrl.text == _lastSyncedNote || _lastSyncedNote == null) {
          _noteCtrl.text = state.note;
          _lastSyncedNote = state.note;
        }
        // Nếu TextField có giá trị khác (user đang nhập), giữ nguyên TextField
      }
      // Sync status controller
      final statusLabel = _getStatusLabel(state.status);
      if (_statusCtrl.text != statusLabel) {
        _statusCtrl.text = statusLabel;
      }
    });

    return Scaffold(
      appBar: const TluAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
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
                    if (materials.isEmpty)
                      _materialTile(
                        theme,
                        title: 'Chưa có nội dung',
                        disabled: true,
                      )
                    else
                      ...materials.map(
                        (m) => _materialTile(
                          theme,
                          title: (m['title'] ?? '').toString(),
                          subtitle: (m['uploaded_at'] ?? '').toString(),
                          url: (m['file_url'] ?? '').toString(),
                          materialId: m['id'] as int?,
                          fileType: (m['file_type'] ?? '').toString(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newMaterialCtrl,
                            enabled: _isEditable(detail),
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
                        // Nút chọn file
                        IconButton(
                          onPressed: _isEditable(detail) ? () async {
                            final title = _newMaterialCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập tiêu đề trước')),
                              );
                              return;
                            }

                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                              allowMultiple: false,
                            );

                            if (result != null && result.files.single.path != null) {
                              final filePath = result.files.single.path!;
                              final success = await viewModel.uploadMaterial(title, filePath);
                              if (success && context.mounted) {
                                _newMaterialCtrl.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã upload tài liệu')),
                                );
                              }
                            }
                          } : null,
                          icon: const Icon(Icons.attach_file),
                          tooltip: 'Chọn file',
                        ),
                        FilledButton(
                          onPressed: _isEditable(detail) ? () async {
                            final title = _newMaterialCtrl.text.trim();
                            if (title.isEmpty) return;
                            final success = await viewModel.addMaterial(title);
                            if (success && context.mounted) {
                              _newMaterialCtrl.clear();
                            }
                          } : null,
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Hiển thị trạng thái dạng TextField (read-only)
                    TextField(
                      readOnly: true,
                      enabled: false,
                      controller: _statusCtrl,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái giảng dạy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: Icon(
                          Icons.info_outline,
                          color: _getStatusColor(state.status),
                        ),
                        filled: true,
                        fillColor: _getStatusColor(state.status).withOpacity(0.1),
                      ),
                      style: TextStyle(
                        color: _getStatusColor(state.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      enabled: _isEditable(detail),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) {
                        // Cập nhật state ngay lập tức khi user nhập
                        viewModel.updateNote(v);
                        // Cập nhật _lastSyncedNote để đánh dấu đây là giá trị từ user
                        _lastSyncedNote = null; // Reset để không sync từ backend nữa
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // Bottom buttons area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Kết thúc buổi học" button - chỉ hiển thị khi status là PLANNED hoặc TEACHING
                  if (_canEndLesson(detail))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleEndLesson(context, viewModel, state),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Kết thúc buổi học'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade700, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  // "Lưu" button
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isEditable(detail) ? () async {
                        // Lấy note trực tiếp từ TextField controller để đảm bảo có giá trị mới nhất
                        final noteFromController = _noteCtrl.text;
                        print('DEBUG submitReport button: noteFromController=$noteFromController, state.note=${state.note}');
                        
                        final success = await viewModel.submitReport(noteOverride: noteFromController);
                        if (context.mounted && success) {
                          // Sau khi save thành công, đợi một chút để loadData() hoàn thành
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            final updatedState = ref.read(scheduleDetailViewModelProvider(widget.sessionId));
                            // Chỉ sync nếu note từ backend khác với giá trị đã sync trước đó
                            if (updatedState.note != _lastSyncedNote) {
                              _lastSyncedNote = updatedState.note;
                              _noteCtrl.text = updatedState.note;
                            }
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu báo cáo buổi học')),
                          );
                        } else if (context.mounted && state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${state.error}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
                      child: Text(_isEditable(detail) ? 'Lưu' : 'Đã kết thúc buổi học'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  /// Check xem có thể kết thúc buổi học không
  /// Chỉ hiển thị khi:
  /// 1. Status là PLANNED hoặc TEACHING
  /// 2. Đã đến hoặc qua thời gian bắt đầu buổi học
  bool _canEndLesson(Map<String, dynamic> detail) {
    final rawStatus = (detail['status'] ?? '').toString().toUpperCase();
    
    // Kiểm tra status trước
    if (rawStatus != 'PLANNED' && rawStatus != 'TEACHING') {
      return false;
    }
    
    // Kiểm tra thời gian: chỉ hiển thị nút nếu đã đến thời gian bắt đầu buổi học
    try {
      final now = DateTime.now();
      
      // Lấy session_date
      final rawDate = ((detail['date'] ??
                  detail['session_date'] ??
                  detail['sessionDate']) ??
              '')
          .toString();
      final dateOnly = rawDate.contains(' ') ? rawDate.split(' ').first : rawDate;
      
      if (dateOnly.isEmpty) {
        // Nếu không có date, cho phép hiển thị (fallback)
        return true;
      }
      
      // Parse date
      DateTime? scheduleDate = DateTime.tryParse(dateOnly);
      if (scheduleDate == null) {
        // Nếu không parse được, cho phép hiển thị (fallback)
        return true;
      }
      
      // Lấy start_time
      String startTimeStr = '';
      if (widget.sessionData != null) {
        final mergedStart = widget.sessionData!['start_time'];
        if (mergedStart != null) startTimeStr = _hhmm(mergedStart);
      }
      
      if (startTimeStr.isEmpty) {
        final ts = detail['timeslot'];
        startTimeStr = _hhmm(detail['start_time'] ??
            detail['start'] ??
            (ts is Map ? ts['start_time'] : null));
      }
      
      if (startTimeStr.isEmpty || startTimeStr == '--:--') {
        // Nếu không có start_time, cho phép hiển thị (fallback)
        return true;
      }
      
      // Parse start_time và tạo DateTime
      final startParts = startTimeStr.split(':');
      if (startParts.length >= 2) {
        final startHour = int.tryParse(startParts[0]) ?? 0;
        final startMinute = int.tryParse(startParts[1]) ?? 0;
        final startDateTime = DateTime(
          scheduleDate.year,
          scheduleDate.month,
          scheduleDate.day,
          startHour,
          startMinute,
        );
        
        // Chỉ hiển thị nút nếu thời gian hiện tại >= thời gian bắt đầu
        return now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime);
      }
    } catch (e) {
      // Nếu có lỗi trong quá trình kiểm tra thời gian, cho phép hiển thị (fallback)
      print('DEBUG _canEndLesson: Error checking time: $e');
      return true;
    }
    
    // Fallback: nếu không kiểm tra được thời gian, cho phép hiển thị
    return true;
  }

  /// Check xem có thể chỉnh sửa không (chỉ khi status chưa là DONE hoặc CANCELED)
  bool _isEditable(Map<String, dynamic> detail) {
    final rawStatus = (detail['status'] ?? '').toString().toUpperCase();
    return rawStatus != 'DONE' && rawStatus != 'CANCELED';
  }

  /// Xử lý logic kết thúc buổi học
  Future<void> _handleEndLesson(
    BuildContext context,
    ScheduleDetailViewModel viewModel,
    ScheduleDetailState state,
  ) async {
    print('DEBUG _handleEndLesson: START - Status: ${state.status}');
    
    try {
      // Kiểm tra xem có buổi học gộp không
      final groupedIds = widget.sessionData?['_grouped_session_ids'] as List?;
      final isGroupedSession = groupedIds != null && groupedIds.isNotEmpty;
      final List<int> sessionIds = isGroupedSession
          ? groupedIds!.map((e) => e as int).toList()
          : [widget.sessionId];
      
      print('DEBUG _handleEndLesson: Is grouped session: $isGroupedSession');
      print('DEBUG _handleEndLesson: Session IDs to process: $sessionIds');
      
      // Kiểm tra status trước khi xử lý
      final currentStatus = state.status.toUpperCase();
      print('DEBUG _handleEndLesson: Current status: $currentStatus');
      
      if (currentStatus != 'PLANNED' && currentStatus != 'TEACHING') {
        print('DEBUG _handleEndLesson: Invalid status, showing error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể kết thúc buổi học. Trạng thái hiện tại: ${_getStatusLabel(currentStatus)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Reload attendance status trước khi check (chỉ một lần cho session chính)
      print('DEBUG _handleEndLesson: Checking attendance...');
      await viewModel.checkAttendance();
      final currentState = ref.read(scheduleDetailViewModelProvider(widget.sessionId));
      print('DEBUG _handleEndLesson: After checkAttendance - Has attendance: ${currentState.hasAttendance}');
      
      // Xác định confirmed dựa trên attendance
      bool confirmed = true;
      
      // Nếu không có attendance, hiển thị dialog xác nhận
      if (currentState.hasAttendance == false) {
        print('DEBUG _handleEndLesson: No attendance, showing confirmation dialog');
        final dialogResult = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Chưa điểm danh sinh viên'),
              content: Text(
                isGroupedSession
                    ? 'Bạn chưa điểm danh sinh viên cho buổi học này. '
                        'Nếu kết thúc buổi học, buổi học sẽ bị hủy. '
                        'Bạn có chắc chắn muốn kết thúc không?'
                    : 'Bạn chưa điểm danh sinh viên cho buổi học này. '
                        'Nếu kết thúc buổi học, hệ thống sẽ đánh dấu lớp là HUỶ. '
                        'Bạn có chắc chắn muốn kết thúc không?',
              ),
            actions: [
              TextButton(
                onPressed: () {
                  print('DEBUG _handleEndLesson: Dialog cancelled');
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () {
                  print('DEBUG _handleEndLesson: Dialog confirmed');
                  Navigator.of(ctx).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Kết thúc buổi học'),
              ),
            ],
          ),
        );

        print('DEBUG _handleEndLesson: Dialog result: $dialogResult');
        if (dialogResult != true || !context.mounted) {
          print('DEBUG _handleEndLesson: Dialog cancelled or context not mounted, returning');
          return;
        }
        confirmed = true;
      }

      // Xử lý kết thúc buổi học
      print('DEBUG _handleEndLesson: About to end lessons for ${sessionIds.length} session(s)');
      bool allSuccess = true;
      List<int> failedSessions = [];
      
      // Lấy note text trước khi kết thúc buổi học
      final noteText = _noteCtrl.text.trim();
      print('DEBUG _handleEndLesson: Note text to save: "$noteText"');
      
      if (isGroupedSession) {
        // Xử lý buổi học gộp: lưu note TRƯỚC khi kết thúc các tiết
        if (noteText.isNotEmpty) {
          print('DEBUG _handleEndLesson: Saving note for ${sessionIds.length} sessions BEFORE ending');
          for (final sessionId in sessionIds) {
            try {
              final noteSuccess = await viewModel.submitReportForSession(sessionId, noteText);
              print('DEBUG _handleEndLesson: Note saved for session $sessionId: $noteSuccess');
            } catch (e) {
              print('DEBUG _handleEndLesson: Exception saving note for session $sessionId: $e');
            }
          }
        }
        
        // Sau đó mới kết thúc tất cả các tiết
        for (final sessionId in sessionIds) {
          print('DEBUG _handleEndLesson: Processing session $sessionId');
          try {
            final success = await viewModel.endLessonForSession(sessionId, confirmed: confirmed);
            if (!success) {
              allSuccess = false;
              failedSessions.add(sessionId);
              print('DEBUG _handleEndLesson: Failed to end session $sessionId');
            }
          } catch (e) {
            allSuccess = false;
            failedSessions.add(sessionId);
            print('DEBUG _handleEndLesson: Exception ending session $sessionId: $e');
          }
        }
      } else {
        // Xử lý buổi học đơn lẻ: lưu note TRƯỚC khi kết thúc
        if (noteText.isNotEmpty) {
          print('DEBUG _handleEndLesson: Saving note BEFORE ending session');
          try {
            final noteSuccess = await viewModel.submitReport(noteOverride: noteText);
            print('DEBUG _handleEndLesson: Note saved: $noteSuccess');
          } catch (e) {
            print('DEBUG _handleEndLesson: Exception saving note: $e');
          }
        }
        
        // Sau đó mới kết thúc buổi học
        print('DEBUG _handleEndLesson: About to call viewModel.endLesson(confirmed: $confirmed)');
        try {
          allSuccess = await viewModel.endLesson(confirmed: confirmed);
          print('DEBUG _handleEndLesson: viewModel.endLesson returned: $allSuccess');
        } catch (e, stackTrace) {
          print('DEBUG _handleEndLesson: Exception in endLesson: $e');
          print('DEBUG _handleEndLesson: Stack trace: $stackTrace');
          allSuccess = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      if (!context.mounted) {
        print('DEBUG _handleEndLesson: Context not mounted after endLesson, returning');
        return;
      }

      // Reload để lấy state mới nhất
      print('DEBUG _handleEndLesson: Reloading state...');
      try {
        await viewModel.refresh();
      } catch (e) {
        print('DEBUG _handleEndLesson: Exception in refresh: $e');
      }
      
      final updatedState = ref.read(scheduleDetailViewModelProvider(widget.sessionId));
      print('DEBUG _handleEndLesson: Updated state - Status: ${updatedState.status}, Error: ${updatedState.error}');

      if (!context.mounted) {
        print('DEBUG _handleEndLesson: Context not mounted after refresh, returning');
        return;
      }

      if (allSuccess) {
        print('DEBUG _handleEndLesson: Success path');
        final finalStatus = updatedState.status.toUpperCase();
        final message = isGroupedSession
            ? 'Đã kết thúc buổi học thành công'
            : (finalStatus == 'DONE'
                ? 'Buổi học đã được kết thúc (ĐÃ HOÀN THÀNH).'
                : 'Buổi học đã được kết thúc (ĐÃ HUỶ).');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: finalStatus == 'DONE' ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        print('DEBUG _handleEndLesson: Failure path');
        // Hiển thị error message
        final errorMessage = failedSessions.isNotEmpty
            ? 'Không thể kết thúc một số buổi học: ${failedSessions.join(", ")}'
            : (updatedState.error ?? 'Không thể kết thúc buổi học');
        
        // Log chi tiết để debug
        print('DEBUG _handleEndLesson: Error - $errorMessage');
        print('DEBUG _handleEndLesson: Status - ${updatedState.status}');
        print('DEBUG _handleEndLesson: Has attendance - ${updatedState.hasAttendance}');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('DEBUG _handleEndLesson: Top-level exception: $e');
      print('DEBUG _handleEndLesson: Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi không mong đợi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    print('DEBUG _handleEndLesson: END');
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
    int? materialId,
    String? fileType,
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
    
    // Kiểm tra xem có thể xóa không (dựa trên status)
    final detail = ref.read(scheduleDetailViewModelProvider(widget.sessionId)).detail ?? {};
    final rawStatus = (detail['status'] ?? '').toString().toUpperCase();
    final isEditable = rawStatus != 'DONE' && rawStatus != 'CANCELED';
    
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nút xóa (chỉ hiển thị khi editable và có materialId)
            if (isEditable && materialId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteMaterial(materialId),
                tooltip: 'Xóa nội dung',
              ),
            // Nút mở file (nếu có URL)
            if (hasUrl) const Icon(Icons.open_in_new),
          ],
        ),
        onTap: hasUrl
            ? () async {
                final uri = Uri.parse(url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        dense: true,
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return 'Đã lên kế hoạch';
      case 'TEACHING':
        return 'Đang dạy';
      case 'DONE':
        return 'Đã hoàn thành';
      case 'CANCELED':
        return 'Đã hủy';
      case 'MAKEUP_PLANNED':
        return 'Lên lịch dạy bù';
      case 'MAKEUP_DONE':
        return 'Đã dạy bù';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return Colors.blue;
      case 'TEACHING':
        return Colors.orange;
      case 'DONE':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      case 'MAKEUP_PLANNED':
        return Colors.purple;
      case 'MAKEUP_DONE':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteMaterial(int materialId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa nội dung này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final viewModel = ref.read(scheduleDetailViewModelProvider(widget.sessionId).notifier);
    final state = ref.read(scheduleDetailViewModelProvider(widget.sessionId));
    final success = await viewModel.deleteMaterial(materialId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa nội dung')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa: ${state.error ?? "Không thể xóa"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
