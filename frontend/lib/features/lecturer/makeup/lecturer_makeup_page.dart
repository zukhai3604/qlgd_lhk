// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Giả lập dữ liệu Model, bạn sẽ thay thế bằng Model thật từ API
class MissedSession {
  final int id;
  final String subjectName;
  final String date;
  final String timeSlot;
  final String reason;

  MissedSession({
    required this.id,
    required this.subjectName,
    required this.date,
    required this.timeSlot,
    required this.reason,
  });
}

class LecturerMakeupPage extends StatefulWidget {
  const LecturerMakeupPage({super.key});

  @override
  State<LecturerMakeupPage> createState() => _LecturerMakeupPageState();
}

class _LecturerMakeupPageState extends State<LecturerMakeupPage> {
  // === QUẢN LÝ TRẠNG THÁI (STATE MANAGEMENT) ===
  bool _isLoading = true;
  String? _error;

  // Dữ liệu cho các dropdown (sẽ được lấy từ API)
  List<MissedSession> _missedSessions = [];
  List<String> _availableTimeSlots = [];
  List<String> _availableRooms = [];

  // Các giá trị được chọn trong form
  MissedSession? _selectedMissedSession;
  DateTime? _selectedMakeupDate;
  String? _selectedMakeupTimeSlot;
  String? _selectedMakeupRoom;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Giả lập việc tải dữ liệu từ API
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Trong thực tế, bạn sẽ gọi API ở đây
      await Future.delayed(const Duration(seconds: 1));

      // Dữ liệu giả
      _missedSessions = [
        MissedSession(
            id: 1,
            subjectName: 'Lập trình phân tán',
            date: '21/09/2025',
            timeSlot: '9:30 - 12:30',
            reason: 'Công tác đột xuất'),
        MissedSession(
            id: 2,
            subjectName: 'Công nghệ Web',
            date: '22/09/2025',
            timeSlot: '7:00 - 9:00',
            reason: 'Ốm'),
      ];
      _availableTimeSlots = ['7:00 - 9:00', '9:10 - 11:10', '15:30 - 18:30'];
      _availableRooms = ['210 - B5', '301 - A2', '404 - C1'];

      // Tự động chọn buổi nghỉ đầu tiên nếu có
      if (_missedSessions.isNotEmpty) {
        _selectedMissedSession = _missedSessions.first;
      }
    } catch (e) {
      _error = 'Không thể tải dữ liệu. Vui lòng thử lại.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Hiển thị loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Giả lập gọi API
      await Future.delayed(const Duration(seconds: 2));

      // Ẩn loading
      if (mounted) Navigator.of(context).pop();

      // Hiển thị thông báo thành công và quay lại
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Gửi yêu cầu dạy bù thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'TRƯỜNG ĐẠI HỌC THỦY LỢI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text(
              'Đăng ký dạy bù',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildForm(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Thay đổi giá trị này để highlight đúng item
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home'); // Điều hướng về trang chủ
              break;
            case 1:
              context.go('/notifications'); // Điều hướng về thông báo
              break;
            case 2:
              context.go('/account'); // Điều hướng về tài khoản
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // === Phần thông tin buổi nghỉ ===
          _buildDropdown<MissedSession>(
            label: 'Môn học',
            value: _selectedMissedSession,
            items: _missedSessions,
            onChanged: (session) {
              setState(() {
                _selectedMissedSession = session;
              });
            },
            itemToString: (session) => session.subjectName,
            validator: (value) =>
                value == null ? 'Vui lòng chọn môn học' : null,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
              label: 'Ngày nghỉ', value: _selectedMissedSession?.date),
          const SizedBox(height: 16),
          _buildReadOnlyField(
              label: 'Ca', value: _selectedMissedSession?.timeSlot),
          const SizedBox(height: 16),
          _buildReadOnlyField(
              label: 'Lý do', value: _selectedMissedSession?.reason),
          const SizedBox(height: 24),

          // === Phần chọn lịch dạy bù ===
          const Text('Chọn lịch dạy bù',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Ngày dạy bù',
            value: _selectedMakeupDate,
            onChanged: (date) {
              setState(() {
                _selectedMakeupDate = date;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown<String>(
            label: 'Ca học',
            value: _selectedMakeupTimeSlot,
            items: _availableTimeSlots,
            onChanged: (slot) {
              setState(() {
                _selectedMakeupTimeSlot = slot;
              });
            },
            validator: (value) => value == null ? 'Vui lòng chọn ca học' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdown<String>(
            label: 'Phòng học',
            value: _selectedMakeupRoom,
            items: _availableRooms,
            onChanged: (room) {
              setState(() {
                _selectedMakeupRoom = room;
              });
            },
            validator: (value) =>
                value == null ? 'Vui lòng chọn phòng học' : null,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitRequest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Gửi yêu cầu dạy bù',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Widget tái sử dụng cho các ô dropdown
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String Function(T)? itemToString,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemToString?.call(item) ?? item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  // Widget tái sử dụng cho các ô chỉ đọc
  Widget _buildReadOnlyField({required String label, String? value}) {
    return TextFormField(
      controller: TextEditingController(text: value ?? '...'),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        fillColor: Colors.grey.shade200,
        filled: true,
      ),
    );
  }

  // Widget riêng cho việc chọn ngày
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
  }) {
    return TextFormField(
      controller: TextEditingController(
        text: value == null ? '' : '${value.day}/${value.month}/${value.year}',
      ),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      validator: (text) =>
          (text == null || text.isEmpty) ? 'Vui lòng chọn ngày' : null,
    );
  }
}
