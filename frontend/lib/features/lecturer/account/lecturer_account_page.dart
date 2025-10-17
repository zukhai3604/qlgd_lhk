import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../widgets/bottom_nav.dart'; // <-- Import the shared widget

class LecturerAccountPage extends StatefulWidget {
  const LecturerAccountPage({super.key});

  @override
  State<LecturerAccountPage> createState() => _LecturerAccountPageState();
}

class _LecturerAccountPageState extends State<LecturerAccountPage> {
  bool loading = true;
  String? error;
  Map<String, dynamic> me = {};

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() => loading = true);
    try {
      const storage = FlutterSecureStorage();
      String? token =
          await storage.read(key: 'access_token') ?? await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        setState(() {
          error = 'Chưa có token. Vui lòng đăng nhập lại.';
          loading = false;
        });
        return;
      }

      final dio = ApiClient.create().dio;
      final opts = Options(headers: {'Authorization': 'Bearer $token'});
      final paths = ['/auth/me', '/me', '/api/me', '/api/user'];

      Response? res;
      DioException? last;
      for (final p in paths) {
        try {
          final r = await dio.get(p, options: opts);
          if ((r.statusCode ?? 500) < 500) {
            res = r;
            break;
          }
        } on DioException catch (e) {
          last = e;
          if (e.response?.statusCode == 401) rethrow;
        }
      }
      if (res == null) {
        if (last != null) throw last;
        throw Exception('Không tìm thấy endpoint /me phù hợp.');
      }
      // Create a non-nullable variable for the data
      final responseData = res.data;
      if (responseData is! Map) throw Exception('Dữ liệu /me không phải là Map.');

      setState(() {
        me = (responseData as Map).cast<String, dynamic>();
        loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        error = 'Lỗi tải hồ sơ (HTTP ${e.response?.statusCode ?? 'null'})';
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Lỗi: $e';
        loading = false;
      });
    }
  }


  String _pickS(List<String> keys) {
    for (final k in keys) {
      dynamic cur = me;
      for (final p in k.split('.')) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && '$cur'.trim().isNotEmpty) return '$cur'.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông tin giảng viên')),
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
        bottomNavigationBar: const BottomNav(currentIndex: 2), // <-- Use the shared widget
      );
    }

    final name   = _pickS(['name','full_name','hoten','ho_ten','user.name','data.name','data.full_name']);
    final dob    = _pickS(['dob','birthday','ngay_sinh','user.dob','data.dob']);
    final gender = _pickS(['gender','gioi_tinh','user.gender','data.gender']);
    final phone  = _pickS(['phone','sdt','so_dien_thoai','user.phone','data.phone']);
    final email  = _pickS(['email','user.email','data.email']);
    final dept   = _pickS(['department','bo_mon','bo_mon.ten','data.department','data.bo_mon']);
    final status = _pickS(['status','trang_thai','data.status']);
    final role   = _pickS(['role','user.role','data.role']);
    final faculty= _pickS(['faculty','khoa','khoa.ten','data.faculty','data.khoa']);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin giảng viên')),
      bottomNavigationBar: const BottomNav(currentIndex: 2), // <-- Use the shared widget
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'TRƯỜNG ĐẠI HỌC THỦY LỢI',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.person, size: 34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _InfoTile(title: 'Tên giảng viên', value: name.isEmpty ? '—' : name),
          _InfoTile(title: 'Ngày sinh', value: dob.isEmpty ? '—' : dob),
          Row(
            children: [
              Expanded(child: _InfoTile(title: 'Giới tính', value: gender.isEmpty ? '—' : gender)),
              const SizedBox(width: 10),
              Expanded(child: _InfoTile(title: 'Số điện thoại', value: phone.isEmpty ? '—' : phone)),
            ],
          ),
          _InfoTile(title: 'Email', value: email.isEmpty ? '—' : email),
          _InfoTile(title: 'Bộ môn', value: dept.isEmpty ? '—' : dept),
          Row(
            children: [
              Expanded(child: _InfoTile(title: 'Trạng thái', value: status.isEmpty ? '—' : status)),
              const SizedBox(width: 10),
              Expanded(child: _InfoTile(title: 'Vai trò', value: role.isEmpty ? '—' : role)),
            ],
          ),
          _InfoTile(title: 'Khoa', value: faculty.isEmpty ? '—' : faculty),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Cài đặt tài khoản'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
