// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/api/makeup_api.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/view_model/makeup_history_view_model.dart';
import 'package:qlgd_lhk/features/lecturer/leave/utils/leave_data_helpers.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';

class MakeupPage extends ConsumerStatefulWidget {
  /// Tương thích ngược: chấp nhận cả `contextData` (mới) & `leaveItem` (cũ)
  const MakeupPage({
    super.key,
    Map<String, dynamic>? contextData,
    Map<String, dynamic>? leaveItem,
  }) : data = contextData ?? leaveItem;

  final Map<String, dynamic>? data;

  @override
  ConsumerState<MakeupPage> createState() => _MakeupPageState();
}

class _MakeupPageState extends ConsumerState<MakeupPage> {
  final _api = LecturerMakeupApi();

  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  DateTime? _selectedDate; // Cho date picker
  Set<int> _selectedPeriods = {}; // Nhiều tiết được chọn (1-15)
  int? _selectedRoomId; // Phòng được chọn
  final _noteCtrl = TextEditingController();

  bool _submitting = false;
  bool _loadingRooms = false;
  List<Map<String, dynamic>> _rooms = [];
  String? _errorMessage; // Lưu lỗi từ server để hiển thị

  // Map tiết số với timeslot_id (sẽ được tính toán dựa trên ngày đã chọn)
  Map<int, int>? _timeslotIdMap;

  @override
  void initState() {
    super.initState();
    _loadRooms();

    final d = widget.data ?? {};
    // Try to extract room_id if available in data
    final roomId = d['room_id'] ?? d['room']?['id'];
    if (roomId != null) {
      _selectedRoomId = int.tryParse(roomId.toString());
    }

    // Try to extract timeslot để map với tiết số
    final timeslot = d['timeslot'] as Map?;
    if (timeslot != null && timeslot['code'] != null) {
      // Parse từ code như "T2_CA1" -> tiết 1
      final code = timeslot['code'].toString();
      final match = RegExp(r'CA(\d+)$').firstMatch(code);
      if (match != null) {
        final period = int.tryParse(match.group(1) ?? '');
        if (period != null && period >= 1 && period <= 15) {
          _selectedPeriods = {period};
        }
      }
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _loadingRooms = true);
    try {
      final rooms = await _api.getRooms();

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _loadingRooms = false;

          // Validate và reset _selectedRoomId nếu không tồn tại trong danh sách
          if (_selectedRoomId != null) {
            final exists = rooms.any(
              (room) => (room['id'] as int?) == _selectedRoomId,
            );
            if (!exists) {
              // Nếu room_id không tồn tại trong danh sách, reset về null
              _selectedRoomId = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRooms = false;
          // Nếu lỗi load rooms, reset selectedRoomId để tránh dropdown assertion
          _selectedRoomId = null;
        });

        // Hiển thị thông báo lỗi cho user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách phòng: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Lấy timeslot_id chính xác từ tiết số và ngày đã chọn bằng cách gọi API
  ///
  /// Cách hoạt động:
  /// - Convert DateTime.weekday (Dart: 1=Mon, 7=Sun) sang Laravel day_of_week (1=Sun, 2=Mon, ..., 7=Sat)
  /// - Gọi API /api/timeslots/by-period với day_of_week và period
  /// - Trả về timeslot_id chính xác từ database
  Future<int?> _getTimeslotIdFromPeriod(int period, DateTime? date) async {
    if (date == null) return null;

    // Nếu đã có map, dùng luôn để tránh gọi API nhiều lần
    if (_timeslotIdMap != null && _timeslotIdMap!.containsKey(period)) {
      return _timeslotIdMap![period];
    }

    // Convert Dart weekday (1=Mon, 7=Sun) sang Laravel day_of_week (1=Sun, 2=Mon, ..., 7=Sat)
    // Laravel: 1=Sunday, 2=Monday, 3=Tuesday, ..., 7=Saturday
    final dartWeekday = date.weekday; // Dart: 1=Mon, 7=Sun
    int laravelDayOfWeek;

    if (dartWeekday == DateTime.sunday) {
      laravelDayOfWeek = 1; // Chủ nhật = 1
    } else {
      laravelDayOfWeek = dartWeekday + 1; // Mon=2, Tue=3, ..., Sat=7
    }

    // Gọi API để lấy timeslot_id chính xác
    final timeslotId =
        await _api.getTimeslotIdByPeriod(laravelDayOfWeek, period);

    // Nếu không tìm thấy timeslot, log để debug
    if (timeslotId == null) {
      // ignore: avoid_print
      print(
          'Warning: Không tìm thấy timeslot cho day_of_week=$laravelDayOfWeek, period=$period, date=${date.toIso8601String()}');
    }

    // Lưu vào cache để tránh gọi lại
    if (timeslotId != null) {
      _timeslotIdMap ??= {};
      _timeslotIdMap![period] = timeslotId;
    }

    return timeslotId;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 180)); // 6 tháng sau

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
        // Reset timeslot map khi đổi ngày
        _timeslotIdMap = null;
      });
    }
  }

  // Các helper methods đã được thay thế bằng LeaveDataExtractor và TimeParser

  Future<List<Map<String, dynamic>>> _buildPayloads() async {
    final src = widget.data ?? {};

    // Kiểm tra xem có grouped leave request IDs không
    final groupedIds = src['_grouped_leave_request_ids'] as List?;
    List<int> leaveRequestIds;

    if (groupedIds != null && groupedIds.isNotEmpty) {
      // Nếu có grouped IDs, tạo makeup request cho TẤT CẢ các leave requests
      leaveRequestIds = groupedIds
          .map((e) => int.tryParse('$e'))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
    } else {
      // Nếu không có grouped, chỉ lấy một leave_request_id
      int? leaveRequestId;
      if (src.containsKey('leave_request_id')) {
        leaveRequestId = int.tryParse(src['leave_request_id'].toString());
      } else if (src.containsKey('id')) {
        leaveRequestId = int.tryParse(src['id'].toString());
      }

      if (leaveRequestId == null || leaveRequestId <= 0) {
        throw Exception('Không tìm thấy leave_request_id hợp lệ');
      }

      leaveRequestIds = [leaveRequestId];
    }

    if (leaveRequestIds.isEmpty) {
      throw Exception('Không tìm thấy leave_request_id hợp lệ');
    }

    final suggestedDate = _dateCtrl.text.trim();
    final roomId = _selectedRoomId;
    final note = _noteCtrl.text.trim();

    // Tạo payloads:
    // - Nếu có grouped leave requests: tạo 1 makeup request cho mỗi period được chọn,
    //   mỗi makeup request trỏ đến leave_request_id tương ứng với period (hoặc dùng leave_request_id đầu tiên nếu không có mapping)
    // - Nếu không grouped: tạo 1 makeup request cho mỗi period được chọn
    final payloads = <Map<String, dynamic>>[];

    if (groupedIds != null && groupedIds.isNotEmpty) {
      // Grouped: Map mỗi period với leave_request_id tương ứng theo thứ tự
      final sortedPeriods = List<int>.from(_selectedPeriods)..sort();

      for (int i = 0; i < sortedPeriods.length; i++) {
        final period = sortedPeriods[i];
        final leaveRequestId =
            i < leaveRequestIds.length ? leaveRequestIds[i] : leaveRequestIds.last;

        if (_selectedDate != null) {
          final timeslotId =
              await _getTimeslotIdFromPeriod(period, _selectedDate);
          if (timeslotId != null) {
            payloads.add({
              'leave_request_id': leaveRequestId,
              'suggested_date': suggestedDate,
              'timeslot_id': timeslotId,
              'room_id': roomId,
              'note': note,
            });
          }
        }
      }
    } else {
      // Không grouped: tạo 1 makeup request cho mỗi period được chọn
      final leaveRequestId = leaveRequestIds.first;
      for (final period in _selectedPeriods) {
        if (_selectedDate != null) {
          final timeslotId =
              await _getTimeslotIdFromPeriod(period, _selectedDate);
          if (timeslotId != null) {
            payloads.add({
              'leave_request_id': leaveRequestId,
              'suggested_date': suggestedDate,
              'timeslot_id': timeslotId,
              'room_id': roomId,
              'note': note,
            });
          }
        }
      }
    }

    return payloads;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null); // Clear error khi submit lại

    if (_selectedPeriods.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng chọn ít nhất một tiết.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final payloads = await _buildPayloads();
      if (payloads.isEmpty) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _errorMessage = 'Không thể tạo đăng ký. Vui lòng kiểm tra lại.';
        });
        return;
      }

      int successCount = 0;
      String? lastError;

      for (final payload in payloads) {
        try {
          await _api.create(payload);
          successCount++;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (!mounted) return;

      if (successCount == payloads.length) {
        // Refresh lịch sử đăng ký dạy bù sau khi tạo thành công
        ref.invalidate(makeupHistoryViewModelProvider);
        Navigator.of(context).pop();
      } else if (successCount > 0) {
        setState(() {
          _submitting = false;
          _errorMessage = 'Đã gửi $successCount/${payloads.length} đăng ký. Lỗi: ${lastError ?? "Không xác định"}';
        });
      } else {
        setState(() {
          _submitting = false;
          _errorMessage = 'Gửi thất bại: ${lastError ?? "Không xác định"}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Gửi thất bại: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data ?? {};
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Sử dụng LeaveDataExtractor để extract đúng dữ liệu từ schedule object
    final subject = LeaveDataExtractor.extractSubject(data);
    final className = LeaveDataExtractor.extractClassName(data);
    final cohort = LeaveDataExtractor.extractCohort(data);
    final room = LeaveDataExtractor.extractRoom(data);
    
    // Extract date và time
    final dateStr = LeaveDataExtractor.extractDate(data);
    final dateLabel = dateStr.isNotEmpty 
        ? DateFormat('EEE, dd/MM/yyyy', 'vi_VN').format(DateTime.parse(dateStr))
        : '';
    
    final timeData = LeaveDataExtractor.extractTime(data);
    final timeRange = '${TimeParser.formatHHMM(timeData.startTime)} - ${TimeParser.formatHHMM(timeData.endTime)}';

    return Scaffold(
      appBar: const TluAppBar(title: 'Đăng ký dạy bù'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ===== Tiêu đề khu thông tin gốc =====
            Text(
              'Thông tin buổi học gốc',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Thông tin buổi học gốc (format giống ảnh 1)
            Card(
              elevation: 0,
              color: cs.surfaceVariant.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: cs.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Môn học với icon bookmark (giống ảnh 1)
                      Row(
                        children: [
                          Icon(
                            Icons.book,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Lớp và Phòng với icon calendar (giống ảnh 1)
                      if (className.isNotEmpty || cohort.isNotEmpty || room.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                [
                                  if (className.isNotEmpty) 'Lớp: $className',
                                  if (cohort.isNotEmpty) cohort,
                                  if (room.isNotEmpty && room != '-') 'Phòng: $room',
                                ].join(' • '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (className.isNotEmpty || cohort.isNotEmpty || room.isNotEmpty)
                        const SizedBox(height: 6),
                      // Ngày và giờ với icon clock (giống ảnh 1)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [
                                if (dateLabel.isNotEmpty) dateLabel,
                                if (timeRange != '--:-- - --:--') timeRange,
                              ].join(' • '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: cs.outline.withOpacity(0.4), height: 1),
            const SizedBox(height: 16),

            // ===== Tiêu đề khu form đăng ký =====
            Text(
              'Thông tin đăng ký dạy bù',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Form trong Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: cs.outline.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Ngày dạy bù - Date Picker
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày dạy bù *',
                          hintText: 'Nhấn để chọn ngày',
                          helperText: 'Chọn ngày muốn dạy bù',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Chọn ngày dạy bù';
                          }
                          try {
                            DateTime.parse(v.trim());
                            return null;
                          } catch (_) {
                            return 'Ngày không hợp lệ';
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Khung giờ - Chọn nhiều tiết
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Khung giờ (Tiết) *',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedPeriods.isEmpty
                                        ? 'Chọn 1–3 tiết liền kề nhau cho buổi dạy bù'
                                        : 'Đã chọn: ${_selectedPeriods.length} tiết',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: _selectedPeriods.isEmpty
                                          ? Colors.grey.shade600
                                          : cs.primary,
                                      fontWeight: _selectedPeriods.isEmpty
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(15, (index) {
                                final period = index + 1; // 1-15
                                final isSelected =
                                    _selectedPeriods.contains(period);
                                final isDisabled = !isSelected &&
                                    _selectedPeriods.length >= 3;

                                return FilterChip(
                                  label: Text('Tiết $period'),
                                  selected: isSelected,
                                  onSelected: isDisabled
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            _errorMessage = null; // Clear error khi chọn tiết
                                            if (selected) {
                                              if (_selectedPeriods.length >=
                                                  3) {
                                                setState(() => _errorMessage = 'Chỉ được chọn tối đa 3 tiết liền kề nhau.');
                                                return;
                                              }

                                              if (_selectedPeriods.isEmpty) {
                                                _selectedPeriods.add(period);
                                              } else {
                                                final sorted =
                                                    List<int>.from(
                                                  _selectedPeriods,
                                                )..sort();
                                                final min = sorted.first;
                                                final max = sorted.last;

                                                if (period == min - 1) {
                                                  _selectedPeriods
                                                      .add(period);
                                                } else if (period ==
                                                    max + 1) {
                                                  _selectedPeriods
                                                      .add(period);
                                                } else {
                                                  setState(() => _errorMessage = 'Chỉ được chọn các tiết liền kề nhau (ví dụ: Tiết 4, 5, 6).');
                                                  return;
                                                }
                                              }
                                            } else {
                                              _selectedPeriods.remove(period);
                                            }
                                          });
                                        },
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chọn 1–3 tiết liền kề (ví dụ: Tiết 4, 5, 6).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedPeriods.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4, left: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Vui lòng chọn ít nhất một tiết',
                              style: TextStyle(
                                color: cs.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      // Hiển thị lỗi từ server hoặc validation màu đỏ
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: cs.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Room - Dropdown từ API (cho phép bỏ trống)
                      DropdownButtonFormField<int?>(
                        value: _loadingRooms ||
                                !_rooms.any(
                                  (r) =>
                                      (r['id'] as int?) ==
                                      _selectedRoomId,
                                )
                            ? null
                            : _selectedRoomId,
                        decoration: InputDecoration(
                          labelText: 'Phòng (tuỳ chọn)',
                          helperText: _loadingRooms
                              ? 'Đang tải danh sách phòng...'
                              : _rooms.isEmpty
                                  ? 'Không có phòng nào'
                                  : 'Chọn phòng học (có thể bỏ trống)',
                          suffixIcon: _loadingRooms
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Không chọn phòng'),
                          ),
                          ..._rooms
                              .where((room) =>
                                  room['id'] != null &&
                                  room['id'] is int)
                              .map(
                            (room) {
                              final roomId = room['id'] as int;
                              final code =
                                  room['code']?.toString() ?? '';
                              final building =
                                  room['building']?.toString();
                              final roomType =
                                  room['room_type']?.toString() ?? '';
                              final displayName =
                                  (building != null &&
                                          building.isNotEmpty)
                                      ? '$code - $building ($roomType)'
                                      : '$code ($roomType)';
                              return DropdownMenuItem<int?>(
                                value: roomId,
                                child: Text(displayName),
                              );
                            },
                          ),
                        ],
                        onChanged: _loadingRooms
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedRoomId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // Ghi chú
                      TextFormField(
                        controller: _noteCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú (tuỳ chọn)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Hiển thị lỗi từ server dưới button
                      if (_errorMessage != null && _selectedPeriods.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: cs.error,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: const Icon(Icons.send),
                          label: Text(
                            _submitting
                                ? 'Đang gửi...'
                                : 'Gửi đăng ký dạy bù',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
