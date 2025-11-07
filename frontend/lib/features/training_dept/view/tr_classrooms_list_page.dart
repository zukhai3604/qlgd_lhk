import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qlgd_lhk/core/api_client.dart';

/// Classrooms List Page - shows all classrooms with search and filter
class ClassroomsListPage extends StatefulWidget {
  const ClassroomsListPage({super.key});

  @override
  State<ClassroomsListPage> createState() => _ClassroomsListPageState();
}

class _ClassroomsListPageState extends State<ClassroomsListPage> {
  final _dio = ApiClient.create().dio;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<dynamic> _classrooms = [];
  String? _selectedBuilding;

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
      final res = await _dio.get('/api/training_department/rooms');
      if (!mounted) return;
      final data = res.data is Map ? res.data['data'] : res.data;
      setState(() {
        _classrooms = data is List ? data : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _classrooms = [];
        _loading = false;
      });
    }
  }

  List<dynamic> _filteredClassrooms() {
    var list = _classrooms;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    }
    return list;
  }

  void _removeFilter() {
    setState(() {
      _selectedBuilding = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClassrooms();
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
                children: [
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Text(
                      'Phòng học',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF545454),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search and filter bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    const Icon(Icons.search, color: Color(0xFF999999), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchCtrl,
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          hintText: 'Tìm kiếm',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color: Color(0xFF999999),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.tune, color: Color(0xFF999999), size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Filter pills (placeholder)
                        if (_selectedBuilding != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Tòa: $_selectedBuilding',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _removeFilter,
                                        child: const Icon(Icons.close, size: 16, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_selectedBuilding != null) const SizedBox(height: 24),

                        // List title
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Danh sách phòng học',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Classrooms list
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
                                'Không có phòng học nào',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: filtered.map((room) {
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (room['name'] ?? 'Phòng học').toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          room['building'] ?? 'Chưa xác định',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
