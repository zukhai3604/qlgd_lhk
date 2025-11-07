import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class TrainingDepartmentRequestsPage extends StatefulWidget {
  const TrainingDepartmentRequestsPage({super.key});
  @override
  State<TrainingDepartmentRequestsPage> createState() => _State();
}

class _State extends State<TrainingDepartmentRequestsPage>
    with SingleTickerProviderStateMixin {
  final _dio = ApiClient.create().dio;
  bool _loading = true;
  List _leave = [], _makeup = [];

  // UI state for Approval screen
  final List<String> _filters = const ['Tất cả', 'Nghỉ', 'Dạy bù', 'Phê duyệt', 'Từ chối'];
  String _selectedFilter = 'Tất cả';
  final TextEditingController _searchCtrl = TextEditingController();
  // Pagination state
  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _ensureAuthHeader() async {
    if (_dio.options.headers['Authorization'] != null) return;
    const storage = FlutterSecureStorage();
    final t1 = await storage.read(key: 'access_token');
    final t2 = t1 ?? await storage.read(key: 'auth_token');
    if (t2 != null && t2.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $t2';
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    await _ensureAuthHeader();
    // Map UI filter. With new pending endpoints, when not filtering by Approved/Rejected, use the PENDING APIs.
    final String? statusParam = _selectedFilter == 'Phê duyệt'
        ? 'APPROVED'
        : _selectedFilter == 'Từ chối'
            ? 'REJECTED'
            : null; // Other filters -> use pending endpoints
    try {
      dynamic r1;
      dynamic r2;

      if (statusParam == null) {
        // Use new endpoints that return only PENDING items
        if (_selectedFilter == 'Nghỉ') {
          r1 = await _dio.get('/api/training_department/approvals/leave/pending');
          r2 = null;
        } else if (_selectedFilter == 'Dạy bù') {
          r1 = null;
          r2 = await _dio.get('/api/training_department/approvals/makeup/pending');
        } else {
          // 'Tất cả' -> pending of both types (screen focuses on approvals)
          r1 = await _dio.get('/api/training_department/approvals/leave/pending');
          r2 = await _dio.get('/api/training_department/approvals/makeup/pending');
        }
      } else {
        // Fall back to generic listing when filtering by Approved/Rejected
        final params = {
          'per_page': 100,
          'status': statusParam,
        };
        r1 = await _dio.get(
          '/api/training_department/requests',
          queryParameters: {...params, 'type': 'leave'},
        );
        r2 = await _dio.get(
          '/api/training_department/requests',
          queryParameters: {...params, 'type': 'makeup'},
        );
      }

      List _extractList(dynamic responseData) {
        // Expect { data: [...] , meta: {...} } or sometimes { data: { data: [...] } }
        if (responseData is Map) {
          final d = responseData['data'];
          if (d is List) return d;
          if (d is Map && d['data'] is List) return (d['data'] as List);
        } else if (responseData is List) {
          return responseData;
        }
        return <dynamic>[];
      }

  final listLeave = r1 != null ? _extractList(r1.data) : <dynamic>[];
  final listMakeup = r2 != null ? _extractList(r2.data) : <dynamic>[];

      setState(() {
        _leave = listLeave;
        _makeup = listMakeup;
        _loading = false;
        _currentPage = 1; // reset to first page on new data
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leave = [];
        _makeup = [];
        _loading = false;
        _currentPage = 1;
      });
      // Optionally show a SnackBar here
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();
    final totalPages = items.isEmpty ? 1 : ((items.length + _pageSize - 1) ~/ _pageSize);
    final currentPage = _currentPage < 1
        ? 1
        : (_currentPage > totalPages ? totalPages : _currentPage);
    final startIndex = (currentPage - 1) * _pageSize;
    final displayed = items.skip(startIndex).take(_pageSize).toList();
    return Scaffold(
      body: Column(
        children: [
          // Top bar (matches the provided UI)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'TRƯỜNG ĐẠI HỌC THUỶ LỢI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1A2EB0),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Text(
                      'Duyệt đơn',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {
                                _currentPage = 1; // reset page on search
                              }),
                              decoration: InputDecoration(
                                hintText: 'Tìm đơn theo tên giảng viên....',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                              _loading = true;
                              _currentPage = 1; // reset page on filter change
                            });
                            _fetch();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.grey[200] : const Color(0xFFF7F2FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF545454)
                                    : const Color(0xFFCAC4D0),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Requests list
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (final it in displayed) ...[
                            _RequestCard(
                              instructor: it.instructor,
                              subject: it.subject,
                              date: it.date,
                              requestType: it.requestType,
                              status: it.status,
                              onTap: () async {
                                final changed = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _RequestDetailsScreen(vm: it),
                                  ),
                                );
                                if (changed == true) {
                                  _fetch();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (items.isEmpty)
                            Center(
                              child: Text(
                                'Không có dữ liệu',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (items.isNotEmpty && totalPages > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: currentPage > 1
                                      ? () => setState(() => _currentPage = currentPage - 1)
                                      : null,
                                  child: const Text('Trước'),
                                ),
                                const SizedBox(width: 12),
                                Text('Trang $currentPage/$totalPages',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: currentPage < totalPages
                                      ? () => setState(() => _currentPage = currentPage + 1)
                                      : null,
                                  child: const Text('Sau'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Utilities for nested access and view models
  String? _getNested(Map? src, List<String> path) {
    dynamic cur = src;
    for (final k in path) {
      if (cur is Map && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return null;
      }
    }
    return cur?.toString();
  }

  List<_ReqVM> _filteredItems() {
    // Group leave rows (2-3 periods in 1 ca) into a single logical item
    final groupedLeaveRaw = _groupRawLeaves(_leave);

    // Merge and transform
    final merged = <_ReqVM>[];
    for (final m in groupedLeaveRaw) {
      merged.add(_toVM(m as Map<String, dynamic>, 'leave'));
    }
    for (final m in _makeup) {
      merged.add(_toVM(m as Map<String, dynamic>, 'makeup'));
    }

    // Filter by selected type
    Iterable<_ReqVM> cur = merged;
    switch (_selectedFilter) {
      case 'Nghỉ':
        cur = cur.where((e) => e.type == 'leave');
        break;
      case 'Dạy bù':
        cur = cur.where((e) => e.type == 'makeup');
        break;
      case 'Phê duyệt':
        cur = cur.where((e) => e.status.toUpperCase() == 'APPROVED');
        break;
      case 'Từ chối':
        cur = cur.where((e) => e.status.toUpperCase() == 'REJECTED');
        break;
      default:
        break;
    }
    // Search by instructor or subject
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      cur = cur.where((e) =>
          e.instructor.toLowerCase().contains(q) || e.subject.toLowerCase().contains(q));
    }

    return cur.toList();
  }

  // Group multiple leave rows (periods) in the same session/ca into 1 item
  List _groupRawLeaves(List input) {
    final Map<String, Map<String, dynamic>> buckets = {};

    String? _get(Map? src, List<String> path) {
      dynamic cur = src;
      for (final k in path) {
        if (cur is Map && cur.containsKey(k)) cur = cur[k]; else return null;
      }
      return cur?.toString();
    }

    for (final e in input) {
      if (e is! Map) continue;
      final m = e.cast<String, dynamic>();
      final id = (m['id'] is int) ? m['id'] as int : int.tryParse((m['id'] ?? '').toString()) ?? 0;
      final scheduleId = _get(m, ['schedule', 'id']);
      final instructor = _get(m, ['lecturer', 'name']) ?? _get(m, ['user', 'name']) ?? '';
      final subj = _get(m, ['schedule', 'assignment', 'subject', 'name']) ?? '';
      final cls = _get(m, ['schedule', 'assignment', 'class_unit', 'name']) ?? '';
      final date = _get(m, ['schedule', 'session_date']) ?? '';
      final start = _get(m, ['schedule', 'timeslot', 'start_time']) ?? '';
      final end = _get(m, ['schedule', 'timeslot', 'end_time']) ?? '';
      final status = (m['status'] ?? '').toString();

      final key = (scheduleId != null && scheduleId.isNotEmpty)
          ? 'schedule:$scheduleId|$status'
          : 'composite:$instructor|$subj|$cls|$date|$start-$end|$status';

      if (!buckets.containsKey(key)) {
        final rep = Map<String, dynamic>.from(m);
        rep['_group_ids'] = <int>[id];
        buckets[key] = rep;
      } else {
        (buckets[key]!['_group_ids'] as List<int>).add(id);
      }
    }

    return buckets.values.toList();
  }

  _ReqVM _toVM(Map<String, dynamic> it, String type) {
    final subj = type == 'leave'
        ? _getNested(it, ['schedule', 'assignment', 'subject', 'name'])
        : _getNested(
            it, ['leave_request', 'schedule', 'assignment', 'subject', 'name']);
    final instructor = _getNested(it, ['lecturer', 'name']) ??
        _getNested(it, ['user', 'name']) ??
        'Giảng viên';
    final cls = type == 'leave'
        ? _getNested(it, ['schedule', 'assignment', 'class_unit', 'name'])
        : _getNested(it,
            ['leave_request', 'schedule', 'assignment', 'class_unit', 'name']);
    final date = type == 'leave'
        ? _getNested(it, ['schedule', 'session_date'])
        : _getNested(it, ['suggested_date']);
    final status = (it['status'] ?? '').toString();
    final id = (it['id'] is int)
        ? it['id'] as int
        : int.tryParse((it['id'] ?? '').toString()) ?? 0;
    final groupIds = (it['_group_ids'] is List)
        ? List<int>.from(it['_group_ids'] as List)
        : <int>[id];

    final periods = (type == 'leave') ? groupIds.length : 1;
    final reqTypeLabel = type == 'leave'
        ? (periods > 1
            ? 'Loại đơn: xin nghỉ dạy ($periods tiết)'
            : 'Loại đơn: xin nghỉ dạy')
        : 'Loại đơn: xin dạy bù';
    final dateLabel =
        (date != null && date.toString().isNotEmpty) ? 'Ngày $date' : 'Ngày -';
    final subjectLabelParts = <String>[];
    if (subj != null && subj.trim().isNotEmpty) subjectLabelParts.add(subj);
    if (cls != null && cls.trim().isNotEmpty) subjectLabelParts.add(cls);
    final subjectLabel = subjectLabelParts.join('  •  ');

    return _ReqVM(
      id: id,
      ids: groupIds,
      type: type,
      instructor: instructor,
      subject: subjectLabel.isEmpty ? (subj ?? 'Môn học') : subjectLabel,
      date: dateLabel,
      requestType: reqTypeLabel,
      status: status,
    );
  }
}

// View model for rendering cards
class _ReqVM {
  final int id;
  final List<int> ids; // grouped ids for leave (multiple rows in one ca)
  final String type; // 'leave' | 'makeup'
  final String instructor;
  final String subject;
  final String date;
  final String requestType;
  final String status; // PENDING | APPROVED | REJECTED
  _ReqVM({
    required this.id,
    required this.ids,
    required this.type,
    required this.instructor,
    required this.subject,
    required this.date,
    required this.requestType,
    required this.status,
  });
}

// UI card identical to the provided ApprovalScreen style
class _RequestCard extends StatelessWidget {
  final String instructor;
  final String subject;
  final String date;
  final String requestType;
  final String status; // PENDING | APPROVED | REJECTED
  final VoidCallback? onTap;
  const _RequestCard({
    required this.instructor,
    required this.subject,
    required this.date,
    required this.requestType,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = _statusPill(status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giảng viên',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    instructor,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF545454),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF545454),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF545454),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requestType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF545454),
                    ),
                  ),
                ],
              ),
            ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: pill.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pill.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF545454),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Bấm vào để xem chi tiết',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Pill _statusPill(String s) {
    final up = s.toUpperCase();
    if (up == 'APPROVED') return const _Pill('Đã duyệt', Color(0xFF46B285));
    if (up == 'REJECTED') return const _Pill('Từ chối', Color(0xFFD22E2E));
    return const _Pill('Đang chờ', Color(0xFFE7983D));
  }
}

class _Pill {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);
}

// Chi tiết đơn
// Màn chi tiết inline (UI giống mẫu yêu cầu)
class _RequestDetailsScreen extends StatefulWidget {
  final _ReqVM vm;
  const _RequestDetailsScreen({required this.vm});

  @override
  State<_RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<_RequestDetailsScreen> {
  final _dio = ApiClient.create().dio;
  bool _busy = false;

  String _safe(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;
  String _dateForDetails(String v) {
    final t = v.trim();
    return t.toLowerCase().startsWith('ngày ')
        ? t.substring(5).trim()
        : t;
  }
  String _subjectForDetails(String v) {
    return v.replaceAll('  •  ', ' - ');
  }

  Future<void> _ensureAuthHeader() async {
    if (_dio.options.headers['Authorization'] != null) return;
    const storage = FlutterSecureStorage();
    final t1 = await storage.read(key: 'access_token');
    final t2 = t1 ?? await storage.read(key: 'auth_token');
    if (t2 != null && t2.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $t2';
    }
  }

  Future<void> _approve() async {
    if (widget.vm.status.toUpperCase() != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ xử lý đơn ở trạng thái ĐANG CHỜ')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _ensureAuthHeader();
      if (widget.vm.type == 'leave' && widget.vm.ids.length > 1) {
        for (final id in widget.vm.ids) {
          final path = '/api/training_department/approvals/leave/$id';
          final res = await _dio.post(path, data: {'status': 'APPROVED'});
          if ((res.statusCode ?? 500) >= 400) {
            throw Exception(res.data is Map && res.data['message'] != null
                ? res.data['message'].toString()
                : 'Lỗi phê duyệt');
          }
        }
      } else {
        final path = widget.vm.type == 'leave'
            ? '/api/training_department/approvals/leave/${widget.vm.id}'
            : '/api/training_department/approvals/makeup/${widget.vm.id}';
        final res = await _dio.post(path, data: {'status': 'APPROVED'});
        if ((res.statusCode ?? 500) >= 400) {
          throw Exception(res.data is Map && res.data['message'] != null
              ? res.data['message'].toString()
              : 'Lỗi phê duyệt');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã phê duyệt')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    if (widget.vm.status.toUpperCase() != 'PENDING') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ xử lý đơn ở trạng thái ĐANG CHỜ')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _ensureAuthHeader();
      if (widget.vm.type == 'leave' && widget.vm.ids.length > 1) {
        for (final id in widget.vm.ids) {
          final path = '/api/training_department/approvals/leave/$id';
          final res = await _dio.post(path, data: {'status': 'REJECTED'});
          if ((res.statusCode ?? 500) >= 400) {
            throw Exception(res.data is Map && res.data['message'] != null
                ? res.data['message'].toString()
                : 'Lỗi từ chối');
          }
        }
      } else {
        // Giả định backend có endpoint từ chối; nếu chưa, dùng approvals với tham số trạng thái
        final path = widget.vm.type == 'leave'
            ? '/api/training_department/approvals/leave/${widget.vm.id}'
            : '/api/training_department/approvals/makeup/${widget.vm.id}';
        final res = await _dio.post(path, data: {'status': 'REJECTED'});
        if ((res.statusCode ?? 500) >= 400) {
          throw Exception(res.data is Map && res.data['message'] != null
              ? res.data['message'].toString()
              : 'Lỗi từ chối');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLeave = widget.vm.type == 'leave';
    final title = isLeave ? 'Chi tiết đơn xin nghỉ dạy' : 'Chi tiết đề xuất dạy bù';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'TRƯỜNG ĐẠI HỌC THUỶ LỢI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1A2EB0),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Giảng viên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                              SizedBox(height: 4),
                              Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                              SizedBox(height: 12),
                              Text('Đơn vị', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(widget.vm.instructor, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 4),
                              Text(_safe(null), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 12),
                              Text(_safe(null), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300], height: 1),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Môn - Lớp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                              SizedBox(height: 12),
                              Text('Ngày - Ca', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                              SizedBox(height: 12),
                              Text('Phòng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_subjectForDetails(widget.vm.subject), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 12),
                              Text(_dateForDetails(widget.vm.date), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 12),
                              Text(_safe(null), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300], height: 1),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lý do', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                              SizedBox(height: 12),
                              Text('Ghi chú', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_safe(null), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 12),
                              Text(_safe(null), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _busy ? null : _reject,
                              borderRadius: BorderRadius.circular(8),
                              child: const Center(
                                child: Text(
                                  'Từ chối',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF648DDB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _busy ? null : _approve,
                              borderRadius: BorderRadius.circular(8),
                              child: const Center(
                                child: Text(
                                  'Phê duyệt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
