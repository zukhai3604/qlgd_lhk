import 'package:flutter/material.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'attendance_api.dart';

class LecturerAttendancePage extends StatefulWidget {
  final int sessionId;
  final String? subjectName;
  final String? className;
  final List<int>? groupedSessionIds; // Danh sách session IDs đã được gộp (nếu có)

  const LecturerAttendancePage({
    super.key,
    required this.sessionId,
    this.subjectName,
    this.className,
    this.groupedSessionIds, // Nhận danh sách session IDs đã gộp
  });

  @override
  State<LecturerAttendancePage> createState() => _LecturerAttendancePageState();
}

class _LecturerAttendancePageState extends State<LecturerAttendancePage> {
  final _api = LecturerAttendanceApi();
  final _searchController = TextEditingController();
  
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  
  // Danh sách session IDs cần điểm danh (bao gồm cả session chính và các session đã gộp)
  List<int> _sessionIdsToMark = [];
  
  // Map để lưu trạng thái điểm danh của từng sinh viên
  final Map<int, String> _attendanceStatus = {}; // student_id -> status
  final Map<int, String> _attendanceNotes = {}; // student_id -> note

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    
    // Xác định danh sách session IDs cần điểm danh
    if (widget.groupedSessionIds != null && widget.groupedSessionIds!.isNotEmpty) {
      // Nếu có danh sách session IDs đã gộp, dùng danh sách đó
      _sessionIdsToMark = widget.groupedSessionIds!;
    } else {
      // Nếu không có, chỉ điểm danh cho session hiện tại
      _sessionIdsToMark = [widget.sessionId];
    }
    
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredStudents = _students;
      });
      return;
    }

    setState(() {
      _filteredStudents = _students.where((item) {
        final student = item['student'] as Map?;
        if (student == null) return false;
        
        final code = student['code']?.toString().toLowerCase() ?? '';
        final name = student['name']?.toString().toLowerCase() ?? '';
        
        return code.contains(query) || name.contains(query);
      }).toList();
    });
  }

  int _getTotalCount() => _students.length;
  
  int _getPresentCount() {
    return _students.where((item) {
      final student = item['student'] as Map?;
      if (student == null) return false;
      final studentId = student['id'] as int?;
      if (studentId == null) return false;
      return (_attendanceStatus[studentId] ?? 'ABSENT').toUpperCase() == 'PRESENT';
    }).length;
  }
  
  int _getAbsentCount() {
    return _students.where((item) {
      final student = item['student'] as Map?;
      if (student == null) return false;
      final studentId = student['id'] as int?;
      if (studentId == null) return false;
      return (_attendanceStatus[studentId] ?? 'ABSENT').toUpperCase() == 'ABSENT';
    }).length;
  }
  
  int _getLateCount() {
    return _students.where((item) {
      final student = item['student'] as Map?;
      if (student == null) return false;
      final studentId = student['id'] as int?;
      if (studentId == null) return false;
      return (_attendanceStatus[studentId] ?? 'ABSENT').toUpperCase() == 'LATE';
    }).length;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Lấy điểm danh từ session đầu tiên (tất cả các sessions trong nhóm đều cùng lớp)
      final list = await _api.getAttendance(widget.sessionId);
      
      // Khởi tạo trạng thái từ dữ liệu API
      for (final item in list) {
        final student = item['student'];
        if (student is Map) {
          final studentId = student['id'];
          if (studentId != null) {
            final status = item['status']?.toString();
            final note = item['note']?.toString();
            
            if (status != null && status != 'null') {
              _attendanceStatus[studentId] = status.toUpperCase();
            } else {
              // Mặc định là ABSENT nếu chưa có điểm danh (theo hình ảnh)
              _attendanceStatus[studentId] = 'ABSENT';
            }
            
            if (note != null && note.isNotEmpty && note != 'null') {
              _attendanceNotes[studentId] = note;
            }
          }
        }
      }
      
      setState(() {
        _students = list;
        _filteredStudents = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không tải được danh sách sinh viên: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      // Tạo danh sách records để gửi lên server
      final records = <Map<String, dynamic>>[];
      
      for (final item in _students) {
        final student = item['student'];
        if (student is Map) {
          final studentId = student['id'];
          if (studentId != null && _attendanceStatus.containsKey(studentId)) {
            records.add({
              'student_id': studentId,
              'status': _attendanceStatus[studentId],
              'note': _attendanceNotes[studentId],
            });
          }
        }
      }

      // Điểm danh cho tất cả các session IDs trong nhóm
      for (final sessionId in _sessionIdsToMark) {
        await _api.saveAttendance(sessionId, records);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu điểm danh thành công'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload để cập nhật dữ liệu
      _load();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu điểm danh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: TluAppBar(
        title: 'Điểm danh sinh viên',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Statistics Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Tổng số
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Tổng số',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getTotalCount()}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Có mặt
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Có mặt',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getPresentCount()}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Vắng
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Vắng',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getAbsentCount()}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Muộn
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Muộn',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getLateCount()}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm theo tên, mã sinh viên...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // List students
                    Expanded(
                      child: _filteredStudents.isEmpty
                          ? Center(
                              child: Text(
                                _students.isEmpty
                                    ? 'Không có sinh viên nào trong lớp'
                                    : 'Không tìm thấy sinh viên',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.builder(
                              // ✅ Tối ưu performance với khoảng cách đẹp hơn
                              itemExtent: 155, // ✅ Tăng từ 130 lên 155 để có khoảng cách đẹp hơn
                              cacheExtent: 500, // Cache items ngoài viewport
                              addAutomaticKeepAlives: false, // Tiết kiệm memory
                              addRepaintBoundaries: true, // Tách repaint boundaries
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final item = _filteredStudents[index];
                                final student = item['student'] as Map?;
                                
                                if (student == null) return const SizedBox.shrink();
                                
                                final studentId = student['id'] as int?;
                                final studentCode = student['code']?.toString() ?? '';
                                final studentName = student['name']?.toString() ?? 'Chưa có tên';
                                
                                if (studentId == null) return const SizedBox.shrink();
                                
                                final currentStatus = _attendanceStatus[studentId] ?? 'ABSENT';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12), // ✅ Tăng từ 8 lên 12
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // ✅ Tăng từ 8 lên 12
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // ✅ Tăng từ (12, 8) lên (16, 14)
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Student Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$studentCode-$studentName',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15, // ✅ Tăng từ 14 lên 15
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6), // ✅ Tăng từ 3 lên 6
                                              Text(
                                                'MSV: $studentCode',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 12, // ✅ Tăng từ 11 lên 12
                                                ),
                                              ),
                                              const SizedBox(height: 4), // ✅ Tăng từ 1 lên 4
                                              Text(
                                                'Lớp: ${widget.className ?? 'N/A'}',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 12, // ✅ Tăng từ 11 lên 12
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 14), // ✅ Tăng từ 8 lên 14
                                        
                                        // Radio Buttons - Compact version
                                        Flexible(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // ✅ Compact Radio buttons - không dùng RadioListTile
                                              _buildCompactRadio(
                                                'Có mặt',
                                                'PRESENT',
                                                currentStatus,
                                                () {
                                                  setState(() {
                                                    _attendanceStatus[studentId] = 'PRESENT';
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 8), // ✅ Tăng từ 2 lên 8
                                              _buildCompactRadio(
                                                'Vắng',
                                                'ABSENT',
                                                currentStatus,
                                                () {
                                                  setState(() {
                                                    _attendanceStatus[studentId] = 'ABSENT';
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 8), // ✅ Tăng từ 2 lên 8
                                              _buildCompactRadio(
                                                'Muộn',
                                                'LATE',
                                                currentStatus,
                                                () {
                                                  setState(() {
                                                    _attendanceStatus[studentId] = 'LATE';
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    // Save button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Lưu'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ✅ Helper method để tạo compact radio button với khoảng cách đẹp hơn
  Widget _buildCompactRadio(
    String label,
    String value,
    String groupValue,
    VoidCallback onTap,
  ) {
    final isSelected = groupValue == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4), // ✅ Thêm border radius cho InkWell
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2), // ✅ Thêm padding để dễ tap hơn
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20, // ✅ Tăng từ 18 lên 20
              height: 20, // ✅ Tăng từ 18 lên 20
              child: Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: (_) => onTap(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6), // ✅ Tăng từ 4 lên 6
            Text(
              label,
              style: TextStyle(
                fontSize: 13, // ✅ Tăng từ 12 lên 13
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, // ✅ Thêm fontWeight khi selected
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

