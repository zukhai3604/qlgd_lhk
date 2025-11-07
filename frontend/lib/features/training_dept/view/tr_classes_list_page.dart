import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/api_client.dart';

/// Classes List Page - shows all classes with search and filter
class ClassesListPage extends StatefulWidget {
  const ClassesListPage({super.key});

  @override
  State<ClassesListPage> createState() => _ClassesListPageState();
}

class _ClassesListPageState extends State<ClassesListPage> {
  final _dio = ApiClient.create().dio;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<dynamic> _classes = [];
  String? _selectedFaculty;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    try {
      final res = await _dio.get('/api/training_department/classes');
      if (!mounted) return;
      final data = res.data is Map ? res.data['data'] : res.data;
      setState(() {
        _classes = data is List ? data : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classes = [];
        _loading = false;
      });
    }
  }

  List<dynamic> _filteredClasses() {
    var list = _classes;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    }
    return list;
  }

  void _removeFilter(String filterType) {
    setState(() {
      if (filterType == 'faculty') {
        _selectedFaculty = null;
      } else if (filterType == 'course') {
        _selectedCourse = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClasses();
    return Scaffold(
      body: Column(
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

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Text(
                      'Lớp học',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF545454),
                      ),
                    ),
                  ),

                  // Search bar with filter button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: 'Tìm kiếm lớp học....',
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
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.tune, color: Colors.grey[600], size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active Filters
                  if (_selectedFaculty != null || _selectedCourse != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_selectedFaculty != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Khoa: $_selectedFaculty',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF545454),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeFilter('faculty'),
                                    child: const Icon(Icons.close, size: 16, color: Color(0xFF545454)),
                                  ),
                                ],
                              ),
                            ),
                          if (_selectedCourse != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Khóa: $_selectedCourse',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF545454),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeFilter('course'),
                                    child: const Icon(Icons.close, size: 16, color: Color(0xFF545454)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_selectedFaculty != null || _selectedCourse != null)
                    const SizedBox(height: 24),

                  // Section title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Danh sách lớp học',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Classes list
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Không có lớp học nào',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: filtered.map((classItem) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ClassCard(
                              id: (classItem['name'] ?? '').toString(),
                              major: _getNested(classItem, ['department', 'name']) ?? 'Chưa xác định',
                              faculty: _getNested(classItem, ['department', 'faculty', 'name']) ?? 'Chưa xác định',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
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
}

class _ClassCard extends StatelessWidget {
  final String id;
  final String major;
  final String faculty;

  const _ClassCard({
    required this.id,
    required this.major,
    required this.faculty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Text(
            id,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF545454),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khoa: $faculty',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF545454),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ngành: $major',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF545454),
            ),
          ),
        ],
      ),
    );
  }
}
