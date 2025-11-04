// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'makeup_api.dart';

class LecturerMakeupPage extends StatefulWidget {
  /// Tương thích ngược: chấp nhận cả `contextData` (mới) & `leaveItem` (cũ)
  const LecturerMakeupPage({
    super.key,
    Map<String, dynamic>? contextData,
    Map<String, dynamic>? leaveItem,
  }) : data = contextData ?? leaveItem;

  final Map<String, dynamic>? data;

  @override
  State<LecturerMakeupPage> createState() => _LecturerMakeupPageState();
}

class _LecturerMakeupPageState extends State<LecturerMakeupPage> {
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
            final exists = rooms.any((room) => 
              (room['id'] as int?) == _selectedRoomId
            );
            if (!exists) {
              // Nếu room_id không tồn tại trong danh sách, reset về null
              _selectedRoomId = null;
            }
          }
        });
      }
    } catch (e, stackTrace) {
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
    final cacheKey = '${date.weekday}_$period';
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
    final timeslotId = await _api.getTimeslotIdByPeriod(laravelDayOfWeek, period);
    
    // Nếu không tìm thấy timeslot, log để debug
    if (timeslotId == null) {
      print('Warning: Không tìm thấy timeslot cho day_of_week=$laravelDayOfWeek, period=$period, date=${date.toIso8601String()}');
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

  String _pick(Map s, List<String> keys, {String def = ''}) {
    for (final k in keys) {
      final v = s[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return def;
  }

  String _subjectOf(Map s) => _pick(s, [
    'subject',
    'subject_name',
    'course_name',
    'title',
    'assignment.subject.name',
  ], def: 'Môn học');

  String _classOf(Map s) {
    var v = _pick(s, ['class_name', 'class', 'class_code', 'group_name']);
    if (v.isNotEmpty) return v;
    final a = s['assignment'];
    if (a is Map) {
      v = _pick(a['class_unit'] as Map? ?? {}, ['name', 'code']);
      if (v.isNotEmpty) return v;
      v = _pick(a['classUnit'] as Map? ?? {}, ['name', 'code']);
    }
    return v;
  }

  String _cohortOf(Map s) {
    var c = _pick(s, ['cohort', 'k', 'course', 'batch']);
    if (c.isNotEmpty && !c.toUpperCase().startsWith('K')) c = 'K$c';
    return c;
  }

  String _dateVN(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final raw = iso.length >= 10 ? iso.substring(0, 10) : iso;
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEE, dd/MM/yyyy', 'vi_VN').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _hhmm(String? t) {
    if (t == null || t.isEmpty) return '--:--';
    final s = t.trim();
    if (s.contains('T')) {
      try {
        final dt = DateTime.parse(s);
        return DateFormat('HH:mm').format(dt);
      } catch (_) {}
    }
    final parts = s.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    return s;
  }

  String _timeOf(Map s) {
    final st = _pick(s, ['start_time', 'startTime', 'timeslot.start', 'period.start', 'slot.start']);
    final et = _pick(s, ['end_time', 'endTime', 'timeslot.end', 'period.end', 'slot.end']);
    return '${_hhmm(st)} - ${_hhmm(et)}';
  }

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
    // - Nếu có grouped leave requests: chỉ tạo 1 makeup request cho group (dùng leave_request_id đầu tiên)
    // - Nếu không grouped: tạo 1 makeup request cho mỗi period được chọn
    final payloads = <Map<String, dynamic>>[];
    
    if (groupedIds != null && groupedIds.isNotEmpty) {
      // Grouped: chỉ tạo 1 makeup request cho group, dùng leave_request_id đầu tiên
      // Tạo 1 request cho mỗi period được chọn (nhưng chỉ dùng 1 leave_request_id đầu tiên)
      final firstLeaveRequestId = leaveRequestIds.first;
      for (final period in _selectedPeriods) {
        if (_selectedDate != null) {
          final timeslotId = await _getTimeslotIdFromPeriod(period, _selectedDate);
          if (timeslotId != null) {
            payloads.add({
              'leave_request_id': firstLeaveRequestId,
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
          final timeslotId = await _getTimeslotIdFromPeriod(period, _selectedDate);
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
    
    if (_selectedPeriods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một tiết.')),
      );
      return;
    }
    
    setState(() => _submitting = true);
    try {
      final payloads = await _buildPayloads();
      if (payloads.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo đăng ký. Vui lòng kiểm tra lại.')),
        );
        setState(() => _submitting = false);
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
        // Không hiển thị SnackBar, quay lại list
        Navigator.of(context).pop(); // quay lại list
      } else if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi $successCount/${payloads.length} đăng ký. Lỗi: ${lastError ?? "Không xác định"}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi thất bại: ${lastError ?? "Không xác định"}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data ?? {};
    final cs = Theme.of(context).colorScheme;

    final subject = _subjectOf(data);
    final className = _classOf(data);
    final cohort = _cohortOf(data);
    final room = _pick(data, ['room', 'room_code', 'roomName']);
    final dateStr = (data['date'] ?? data['leave_date'] ?? data['session_date'])?.toString();
    final dateLabel = _dateVN(dateStr);
    final timeRange = _timeOf(data);

    return Scaffold(
      appBar: const TluAppBar(title: 'Đăng ký dạy bù'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Bảng thông tin (giống bên Leave)
          Card(
            color: cs.surfaceVariant.withOpacity(.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primary.withOpacity(.45), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (className.isNotEmpty || cohort.isNotEmpty || room.isNotEmpty)
                  Text(
                    [
                      if (className.isNotEmpty) 'Lớp: $className',
                      if (cohort.isNotEmpty) cohort,
                      if (room.isNotEmpty) '• Phòng: $room',
                    ].join(' - ').replaceAll(' - •', ' •'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (dateLabel.isNotEmpty) dateLabel,
                    if (timeRange != '--:-- - --:--') timeRange,
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              // Ngày dạy bù - Date Picker
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Ngày dạy bù *',
                  hintText: 'Nhấn để chọn ngày',
                  helperText: 'Chọn ngày muốn dạy bù',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Chọn ngày dạy bù';
                  try {
                    DateTime.parse(v.trim());
                    return null;
                  } catch (_) {
                    return 'Ngày không hợp lệ';
                  }
                },
              ),
              const SizedBox(height: 12),

              // Khung giờ - Chọn nhiều tiết (Checkbox list)
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
                        Text(
                          'Khung giờ (Tiết) *',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (_selectedPeriods.isNotEmpty)
                          Text(
                            ' (${_selectedPeriods.length} tiết)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
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
                        final isSelected = _selectedPeriods.contains(period);
                        final isDisabled = !isSelected && _selectedPeriods.length >= 3;
                        
                        return FilterChip(
                          label: Text('Tiết $period'),
                          selected: isSelected,
                          onSelected: isDisabled ? null : (selected) {
                            setState(() {
                              if (selected) {
                                // Kiểm tra xem có thể thêm tiết này không
                                if (_selectedPeriods.length >= 3) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Chỉ được chọn tối đa 3 tiết liền kề nhau.')),
                                  );
                                  return;
                                }
                                
                                if (_selectedPeriods.isEmpty) {
                                  // Tiết đầu tiên: cho phép chọn
                                  _selectedPeriods.add(period);
                                } else {
                                  // Kiểm tra tiết có liền kề với các tiết đã chọn không
                                  final sorted = List<int>.from(_selectedPeriods)..sort();
                                  final min = sorted.first;
                                  final max = sorted.last;
                                  
                                  if (period == min - 1) {
                                    // Thêm vào đầu
                                    _selectedPeriods.add(period);
                                  } else if (period == max + 1) {
                                    // Thêm vào cuối
                                    _selectedPeriods.add(period);
                                  } else {
                                    // Không liền kề: không cho chọn
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Chỉ được chọn các tiết liền kề nhau (ví dụ: Tiết 4, 5, 6).')),
                                    );
                                    return;
                                  }
                                }
                              } else {
                                // Bỏ chọn
                                _selectedPeriods.remove(period);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn 1-3 tiết liền kề nhau (ví dụ: Tiết 4, 5, 6)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedPeriods.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'Vui lòng chọn ít nhất một tiết',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Room - Dropdown từ API
              DropdownButtonFormField<int>(
                value: _loadingRooms || _selectedRoomId == null || !_rooms.any((r) => (r['id'] as int?) == _selectedRoomId)
                    ? null 
                    : _selectedRoomId,
                decoration: InputDecoration(
                  labelText: 'Phòng (tuỳ chọn)',
                  helperText: _loadingRooms 
                      ? 'Đang tải danh sách phòng...' 
                      : _rooms.isEmpty 
                          ? 'Không có phòng nào' 
                          : 'Chọn phòng học',
                  suffixIcon: _loadingRooms 
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Không chọn phòng'),
                  ),
                  // Đảm bảo không có duplicate values bằng cách filter null và distinct
                  ..._rooms
                      .where((room) {
                        final id = room['id'];
                        return id != null && id is int;
                      })
                      .map((room) {
                        final roomId = room['id'] as int;
                        final code = room['code']?.toString() ?? '';
                        final building = room['building']?.toString();
                        final roomType = room['room_type']?.toString() ?? '';
                        final displayName = building != null && building.isNotEmpty
                            ? '$code - $building ($roomType)'
                            : '$code ($roomType)';
                        return DropdownMenuItem<int>(
                          value: roomId,
                          child: Text(displayName),
                        );
                      })
                      .toList(),
                ],
                onChanged: _loadingRooms 
                    ? null 
                    : (value) {
                        setState(() {
                          _selectedRoomId = value;
                        });
                      },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
              ),
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.send),
                label: Text(_submitting ? 'Đang gửi...' : 'Gửi đăng ký dạy bù'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
