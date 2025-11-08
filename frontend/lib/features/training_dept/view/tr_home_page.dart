
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/core/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:qlgd_lhk/features/training_dept/view/tr_reports_page.dart';
import 'package:qlgd_lhk/features/training_dept/view/tr_notifications_page.dart';

class TrainingDepartmentHomePage extends StatefulWidget {
  const TrainingDepartmentHomePage({super.key});

  @override
  State<TrainingDepartmentHomePage> createState() => _TrainingDepartmentHomePageState();
}

class _TrainingDepartmentHomePageState extends State<TrainingDepartmentHomePage> {
  String _activeTab = 'home';
  final _dio = ApiClient.create().dio;

  String? _greetingName;
  int? _statLecturersNow;
  int? _statRoomsInUse;
  int? _statRoomsFree;
  int? _statPending;

  @override
  void initState() {
    super.initState();
    _fetchHomeInfo();
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

  Future<void> _fetchHomeInfo() async {
    try {
      await _ensureAuthHeader();
      // Profile for greeting
      try {
        final res = await _dio.get('/api/training_department/me/profile');
        final data = (res.data is Map) ? (res.data['data'] as Map?) : null;
        final name = data != null ? data['name']?.toString() : null;
        _greetingName = (name != null && name.isNotEmpty) ? name : null;
      } catch (_) {}

      // Quick stats
      try {
        final st = await _dio.get('/api/training_department/stats/quick');
        final d = (st.data is Map) ? (st.data['data'] as Map?) : null;
        _statLecturersNow = ((d?['lecturers_teaching_now']) as num?)?.toInt();
        _statRoomsInUse   = ((d?['rooms_in_use_now']) as num?)?.toInt();
        _statRoomsFree    = ((d?['rooms_free_now']) as num?)?.toInt();
        _statPending      = ((d?['pending_requests_total']) as num?)?.toInt();
      } catch (_) {}
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // "Status bar" mimic (for visual parity with the reference UI)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('9:30', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  Row(
                    children: [
                      Container(width: 18, height: 10, color: const Color(0xFF111827)),
                      const SizedBox(width: 6),
                      Container(width: 18, height: 10, color: const Color(0xFF111827)),
                      const SizedBox(width: 6),
                      Container(width: 18, height: 10, color: const Color(0xFF111827)),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
        child: _activeTab == 'account'
          ? const _AccountContent()
          : _activeTab == 'notif'
                          ? const TrainingNotificationsPage()
                          : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 96),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Header (University name)
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: const Center(
                              child: Text(
                                'TRƯỜNG ĐẠI HỌC THUỶ LỢI',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB), // blue-600
                                ),
                              ),
                            ),
                          ),

                          // Greeting card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Xin chào,', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                                  Text(
                                    (_greetingName != null && _greetingName!.isNotEmpty)
                                        ? _greetingName!
                                        : 'Phòng Đào tạo',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Quick stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Thống kê nhanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF111827),
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                                        ),
                                      ),
                                      onPressed: () {},
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                      label: const Text('Học kỳ I 2025', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                GridView.count(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  crossAxisCount: 1,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  children: [
                                    _StatCard(
                                      label: 'Giảng viên đang dạy',
                                      value: (_statLecturersNow ?? 0).toString(),
                                      color: const Color(0xFF22C55E),
                                    ),
                                    _StatCard(
                                      label: 'Lớp học đang được sử dụng',
                                      value: (_statRoomsInUse ?? 0).toString(),
                                      color: const Color(0xFF3B82F6),
                                    ),
                                    _StatCard(
                                      label: 'Lớp học đang trống',
                                      value: (_statRoomsFree ?? 0).toString(),
                                      color: const Color(0xFFEF4444),
                                    ),
                                    _StatCard(
                                      label: 'Tổng số đơn cần phê duyệt',
                                      value: (_statPending ?? 0).toString(),
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Tools
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Công cụ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                                const SizedBox(height: 8),
                                GridView.count(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  crossAxisCount: 1,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  children: [
                                    _ToolButton(label: 'Sinh lịch chỉ tiết', bg: const Color(0xFF22C55E), icon: Icons.calendar_month, onTap: () => context.push('/training-dept/schedule')),
                                    _ToolButton(label: 'Duyệt đơn', bg: const Color(0xFF3B82F6), icon: Icons.task_alt, onTap: () => context.push('/training-dept/requests')),
                                    _ToolButton(label: 'Báo cáo thống kê', bg: const Color(0xFFEF4444), icon: Icons.query_stats, onTap: () => context.push('/training-dept/reports')),
                                    _ToolButton(label: 'Dữ liệu', bg: const Color(0xFFF59E0B), icon: Icons.folder, onTap: () => context.push('/training-dept/data')),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Pending requests today (live)
                          const _TodayPendingRequests(),
                        ],
                      ),
                    ),
            ),

            // Bottom tab bar
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomItem(
                    icon: Icons.home_rounded,
                    label: 'Trang chủ',
                    active: _activeTab == 'home',
                    onTap: () => setState(() => _activeTab = 'home'),
                  ),
                  _BottomItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Thông báo',
                    active: _activeTab == 'notif',
                    onTap: () => setState(() => _activeTab = 'notif'),
                  ),
                  _BottomItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Tài khoản',
                    active: _activeTab == 'account',
                    onTap: () => setState(() => _activeTab = 'account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Today Pending Requests widget – fetches today's PENDING items and renders live cards
class _TodayPendingRequests extends StatefulWidget {
  const _TodayPendingRequests();

  @override
  State<_TodayPendingRequests> createState() => _TodayPendingRequestsState();
}

class _TodayPendingRequestsState extends State<_TodayPendingRequests> {
  final _dio = ApiClient.create().dio;
  bool _loading = true;
  String? _error;
  List<_TodayReqVM> _items = const [];

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

  String _todayYMD() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _fmtDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '-';
    final p = ymd.split('-');
    if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    return ymd;
  }

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

  List _extractList(dynamic responseData) {
    if (responseData is Map) {
      final d = responseData['data'];
      if (d is List) return d;
      if (d is Map && d['data'] is List) return (d['data'] as List);
    } else if (responseData is List) {
      return responseData;
    }
    return <dynamic>[];
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _ensureAuthHeader();
      final params = {'per_page': 100, 'status': 'PENDING'};
      final rLeave = await _dio.get(
        '/api/training_department/requests',
        queryParameters: {...params, 'type': 'leave'},
      );
      final rMakeup = await _dio.get(
        '/api/training_department/requests',
        queryParameters: {...params, 'type': 'makeup'},
      );

      final listLeave = _extractList(rLeave.data);
      final listMakeup = _extractList(rMakeup.data);

      final today = _todayYMD();
      final items = <_TodayReqVM>[];

      for (final raw in listLeave) {
        final m = (raw as Map).cast<String, dynamic>();
        final date = _getNested(m, ['schedule', 'session_date']);
        if (date != today) continue;
        final subj = _getNested(m, ['schedule', 'assignment', 'subject', 'name']);
        final cls = _getNested(m, ['schedule', 'assignment', 'class_unit', 'name']);
        final instructor = _getNested(m, ['lecturer', 'name']) ?? _getNested(m, ['user', 'name']) ?? 'Giảng viên';
        final id = int.tryParse((m['id'] ?? '').toString()) ?? 0;
        final start = _getNested(m, ['schedule', 'timeslot', 'start_time']);
        final end = _getNested(m, ['schedule', 'timeslot', 'end_time']);
        final time = (start != null && end != null) ? '$start - $end' : '-';
        final course = [if (subj != null && subj.trim().isNotEmpty) subj, if (cls != null && cls.trim().isNotEmpty) cls].join('  •  ');
        items.add(_TodayReqVM(
          id: id,
          type: 'leave',
          instructor: instructor,
          course: course.isEmpty ? (subj ?? 'Môn học') : course,
          date: _fmtDate(date),
          time: time,
          room: '-',
          status: (m['status'] ?? '').toString(),
        ));
      }

      for (final raw in listMakeup) {
        final m = (raw as Map).cast<String, dynamic>();
        final date = _getNested(m, ['suggested_date']);
        if (date != today) continue;
        final subj = _getNested(m, ['leave_request', 'schedule', 'assignment', 'subject', 'name']);
        final cls = _getNested(m, ['leave_request', 'schedule', 'assignment', 'class_unit', 'name']);
        final instructor = _getNested(m, ['lecturer', 'name']) ?? _getNested(m, ['user', 'name']) ?? 'Giảng viên';
        final id = int.tryParse((m['id'] ?? '').toString()) ?? 0;
        final start = _getNested(m, ['leave_request', 'schedule', 'timeslot', 'start_time']);
        final end = _getNested(m, ['leave_request', 'schedule', 'timeslot', 'end_time']);
        final time = (start != null && end != null) ? '$start - $end' : '-';
        final course = [if (subj != null && subj.trim().isNotEmpty) subj, if (cls != null && cls.trim().isNotEmpty) cls].join('  •  ');
        items.add(_TodayReqVM(
          id: id,
          type: 'makeup',
          instructor: instructor,
          course: course.isEmpty ? (subj ?? 'Môn học') : course,
          date: _fmtDate(date),
          time: time,
          room: '-',
          status: (m['status'] ?? '').toString(),
        ));
      }

      // Sort by id desc, and show top 3 for compact UI
      items.sort((a, b) => b.id.compareTo(a.id));
      setState(() {
        _items = items.take(3).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _items = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đơn chờ duyệt - hôm nay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_error != null)
            Text('Lỗi tải dữ liệu: $_error', style: const TextStyle(color: Colors.red))
          else if (_items.isEmpty)
            Text('Không có đơn chờ duyệt hôm nay', style: TextStyle(color: Colors.grey[500]))
          else
            Column(
              children: [
                for (final it in _items) ...[
                  GestureDetector(
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _TodayRequestDetailsScreen(vm: it),
                        ),
                      );
                      if (changed == true) {
                        _fetch();
                      }
                    },
                    child: _PendingRequestCard(
                      instructor: it.instructor,
                      course: it.course,
                      date: it.date,
                      time: it.time,
                      room: it.room,
                      type: it.type == 'leave' ? 'Xin nghỉ' : 'Dạy bù',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TodayReqVM {
  final int id;
  final String type; // 'leave' | 'makeup'
  final String instructor;
  final String course;
  final String date; // dd/MM/yyyy
  final String time; // e.g. 07:00 - 09:00
  final String room;
  final String status; // PENDING | APPROVED | REJECTED
  _TodayReqVM({
    required this.id,
    required this.type,
    required this.instructor,
    required this.course,
    required this.date,
    required this.time,
    required this.room,
    required this.status,
  });
}

// Minimal details screen for Today items with Approve/Reject actions
class _TodayRequestDetailsScreen extends StatefulWidget {
  final _TodayReqVM vm;
  const _TodayRequestDetailsScreen({required this.vm});

  @override
  State<_TodayRequestDetailsScreen> createState() => _TodayRequestDetailsScreenState();
}

class _TodayRequestDetailsScreenState extends State<_TodayRequestDetailsScreen> {
  final _dio = ApiClient.create().dio;
  bool _busy = false;

  Future<void> _ensureAuthHeader() async {
    if (_dio.options.headers['Authorization'] != null) return;
    const storage = FlutterSecureStorage();
    final t1 = await storage.read(key: 'access_token');
    final t2 = t1 ?? await storage.read(key: 'auth_token');
    if (t2 != null && t2.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $t2';
    }
  }

  String _safe(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

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
      final path = widget.vm.type == 'leave'
          ? '/api/training_department/approvals/leave/${widget.vm.id}'
          : '/api/training_department/approvals/makeup/${widget.vm.id}';
      final res = await _dio.post(path, data: {'status': 'APPROVED'});
      if ((res.statusCode ?? 500) >= 400) {
        throw Exception(res.data is Map && res.data['message'] != null
            ? res.data['message'].toString()
            : 'Lỗi phê duyệt');
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
      final path = widget.vm.type == 'leave'
          ? '/api/training_department/approvals/leave/${widget.vm.id}'
          : '/api/training_department/approvals/makeup/${widget.vm.id}';
      final res = await _dio.post(path, data: {'status': 'REJECTED'});
      if ((res.statusCode ?? 500) >= 400) {
        throw Exception(res.data is Map && res.data['message'] != null
            ? res.data['message'].toString()
            : 'Lỗi từ chối');
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
    final title = widget.vm.type == 'leave' ? 'Chi tiết đơn xin nghỉ dạy' : 'Chi tiết đề xuất dạy bù';

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
                              Text(widget.vm.course.replaceAll('  •  ', ' - '), textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 12),
                              Text(widget.vm.date, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
                              const SizedBox(height: 12),
                              Text(widget.vm.room, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF545454))),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback onTap;
  const _ToolButton({required this.icon, required this.label, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final String instructor;
  final String course;
  final String date;
  final String time;
  final String room;
  final String type;
  const _PendingRequestCard({
    required this.instructor,
    required this.course,
    required this.date,
    required this.time,
    required this.room,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.description, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Color(0xFF3730A3),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(instructor, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(course, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(icon: Icons.calendar_today, text: date),
                    _Chip(icon: Icons.access_time, text: time),
                    _Chip(icon: Icons.room, text: room),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF111827) : const Color(0xFF9CA3AF)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: active ? const Color(0xFF111827) : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    ); 
  }
}

// Account tab content – matches the provided reference UI exactly
class _AccountContent extends StatefulWidget {
  const _AccountContent();

  @override
  State<_AccountContent> createState() => _AccountContentState();
}

class _AccountContentState extends State<_AccountContent> {
  final _dio = ApiClient.create().dio;
  bool _loading = true;
  String? _name, _email, _phone, _gender, _dob, _position, _avatarUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _ensureAuthHeader();
      if (_dio.options.headers['Authorization'] == null) {
        throw Exception('Bạn chưa đăng nhập');
      }
      final res = await _dio.get('/api/training_department/me/profile');
      if ((res.statusCode ?? 500) >= 400) {
        throw Exception(res.data is Map && res.data['message'] != null
            ? res.data['message'].toString()
            : 'Lỗi tải hồ sơ');
      }
      // Parse flexible structure
      Map<String, dynamic>? data;
      if (res.data is Map) {
        final top = res.data as Map;
        if (top['data'] is Map) {
          data = Map<String, dynamic>.from(top['data']);
        }
      }
      Map<String, dynamic>? staff;
      if (data != null && data['training_staff'] is Map) {
        staff = Map<String, dynamic>.from(data['training_staff']);
      }

      String? gender = staff?['gender']?.toString();
      if (gender != null) {
        final g = gender.toLowerCase();
        if (g == 'male' || g == 'nam' || g == 'm') gender = 'Nam';
        else if (g == 'female' || g == 'nu' || g == 'nữ' || g == 'f') gender = 'Nữ';
      }

      String? dob = staff?['date_of_birth']?.toString();
      if (dob != null && dob.contains('-')) {
        final p = dob.split('-');
        if (p.length == 3) {
          dob = '${p[2]}/${p[1]}/${p[0]}';
        }
      }

      setState(() {
        _name = data?['name']?.toString();
        _email = data?['email']?.toString();
        _phone = data?['phone']?.toString();
        _gender = gender;
        _dob = dob;
        _position = staff?['position']?.toString();
        final staffAvatar = staff?['avatar_url']?.toString();
        final userAvatar = data?['avatar_url']?.toString();
        _avatarUrl = (staffAvatar != null && staffAvatar.isNotEmpty) ? staffAvatar : userAvatar;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _ensureAuthHeader() async {
    if (_dio.options.headers['Authorization'] != null) return;
    final storage = const FlutterSecureStorage();
    final t1 = await storage.read(key: 'access_token');
    final t2 = t1 ?? await storage.read(key: 'auth_token');
    if (t2 != null && t2.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $t2';
    }
  }

  String _safe(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[600]),
              const SizedBox(height: 12),
              Text('Không tải được hồ sơ người dùng', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF545454))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Avatar with edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: NetworkImage(_avatarUrl?.isNotEmpty == true
                        ? _avatarUrl!
                        : 'https://placehold.co/120x120'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Info Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Họ tên card
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Họ tên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(_safe(_name), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Ngày sinh card
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ngày sinh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(_safe(_dob), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Giới tính and Số điện thoại row
                Row(
                  children: [
                    Expanded(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giới tính', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                            const SizedBox(height: 8),
                            Text(_safe(_gender), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Số điện thoại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                            const SizedBox(height: 8),
                            Text(_safe(_phone), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email card
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(_safe(_email), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Chức vụ card
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chức vụ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(_safe(_position), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Cài đặt section
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cài đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 16),
                      // Cài đặt tài khoản
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 24, color: Colors.grey[700]),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text('Cài đặt tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 16),
                      // Trợ giúp
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, size: 24, color: Colors.grey[700]),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text('Trợ giúp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 16),
                      // Report
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 24, color: Colors.grey[700]),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text('Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 16),
                      // Đăng xuất
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận đăng xuất'),
                              content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            final storage = const FlutterSecureStorage();
                            await storage.delete(key: 'access_token');
                            await storage.delete(key: 'auth_token');
                            await storage.delete(key: 'user_role');
                            
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.logout, size: 24, color: Colors.red),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
