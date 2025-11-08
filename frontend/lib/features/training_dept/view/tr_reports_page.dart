import 'package:flutter/material.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class TrainingDepartmentReportsPage extends StatefulWidget {
  const TrainingDepartmentReportsPage({super.key});
  @override
  State<TrainingDepartmentReportsPage> createState() => _State();
}

class _State extends State<TrainingDepartmentReportsPage> {
  final _dio = ApiClient.create().dio;
  
  String selectedSemester = 'Học kỳ I 2025';
  String? selectedDepartment;
  String? selectedInstructor;
  
  Map _overview = {};
  List _bySubject = [], _byLecturer = [];
  List<String> _departments = [];
  List<String> _instructors = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _load();
  }

  Future<void> _loadFilters() async {
    try {
      // Load danh sách khoa
      final deptResp = await _dio.get('/api/training_department/faculties');
      final deptData = deptResp.data['data'] as List? ?? [];
      
      // Load danh sách giảng viên
      final lecturerResp = await _dio.get('/api/training_department/lecturers');
      final lecturerData = lecturerResp.data['data'] as List? ?? [];
      
      setState(() {
        _departments = deptData.map((d) => d['name'].toString()).toList();
        _instructors = lecturerData.map((l) => l['name'].toString()).toList();
        
        if (_departments.isNotEmpty) {
          selectedDepartment = _departments.first;
        }
        if (_instructors.isNotEmpty) {
          selectedInstructor = _instructors.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    final q = {
      'semester_label': selectedSemester,
      if (selectedDepartment != null) 'department': selectedDepartment,
      if (selectedInstructor != null) 'lecturer': selectedInstructor,
    };
    
    try {
      final o = await _dio.get(
        '/api/training_department/reports/overview',
        queryParameters: q,
      );
      final s = await _dio.get(
        '/api/training_department/reports/subject-progress',
        queryParameters: q,
      );
      final l = await _dio.get(
        '/api/training_department/reports/lecturer-progress',
        queryParameters: q,
      );
      
      setState(() {
        _overview = (o.data['data'] as List).isNotEmpty
            ? (o.data['data'] as List).first
            : {};
        _bySubject = s.data['data'] ?? [];
        _byLecturer = l.data['data'] ?? [];
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với nút back
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
            const SizedBox(height: 16),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Báo cáo thống kê',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildDropdown(
                    selectedSemester,
                    ['Học kỳ I 2025', 'Học kỳ II 2025', 'Học kỳ I 2024'],
                    (value) => setState(() {
                      selectedSemester = value;
                      _load();
                    }),
                  ),
                  if (_departments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDropdown(
                      selectedDepartment ?? _departments.first,
                      _departments,
                      (value) => setState(() {
                        selectedDepartment = value;
                        _load();
                      }),
                    ),
                  ],
                  if (_instructors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDropdown(
                      selectedInstructor ?? _instructors.first,
                      _instructors,
                      (value) => setState(() {
                        selectedInstructor = value;
                        _load();
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Loading indicator
            if (_loading) const Center(child: CircularProgressIndicator()),
            
            // Stats Cards
            if (!_loading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      'Đã dạy',
                      '${_overview['taught_count'] ?? 0}',
                      const Color(0xFF46B285),
                    ),
                    _buildStatCard(
                      'Số buổi còn lại',
                      '${(_overview['total_sessions'] ?? 0) - (_overview['taught_count'] ?? 0)}',
                      const Color(0xFF648DDB),
                    ),
                    _buildStatCard(
                      'Buổi nghỉ',
                      '${_overview['absent_count'] ?? 0}',
                      const Color(0xFFD22E2E),
                    ),
                    _buildStatCard(
                      'Số buổi dạy bù',
                      '${_overview['makeup_count'] ?? 0}',
                      const Color(0xFFE7983D),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Progress Bars Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiến độ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Progress by Subject
                    if (_bySubject.isNotEmpty) ...[
                      const Text(
                        'Theo môn học',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._bySubject.take(3).map((item) {
                        final name = item['subject_name'] ?? 'N/A';
                        final completed = item['taught_count'] ?? 0;
                        final total = item['total_sessions'] ?? 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildProgressItem(name, completed, total),
                        );
                      }),
                    ],
                    
                    // Progress by Lecturer
                    if (_byLecturer.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Theo giảng viên',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._byLecturer.take(3).map((item) {
                        final name = item['lecturer_name'] ?? 'N/A';
                        final completed = item['taught_count'] ?? 0;
                        final total = item['total_sessions'] ?? 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildProgressItem(name, completed, total),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String value, List<String> items, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
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
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String name, int completed, int total) {
    double percentage = total > 0 ? completed / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$completed/$total buổi',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF46B285)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completed buổi',
              style: const TextStyle(fontSize: 13, color: Color(0xFF46B285)),
            ),
            Text(
              '${total - completed} buổi',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

