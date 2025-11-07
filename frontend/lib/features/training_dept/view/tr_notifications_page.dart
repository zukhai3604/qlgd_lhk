import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qlgd_lhk/core/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TrainingNotificationsPage extends StatefulWidget {
  const TrainingNotificationsPage({super.key});

  @override
  State<TrainingNotificationsPage> createState() => _TrainingNotificationsPageState();
}

class _TrainingNotificationsPageState extends State<TrainingNotificationsPage> {
  final _dio = ApiClient.create().dio;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _ensureAuthHeader().then((_) => _fetch());
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
    try {
      await _ensureAuthHeader();
      
      final res = await _dio.get('/api/training_department/notifications');
      final data = res.data['data'] as List? ?? [];
      _items = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Lấy số thông báo chưa đọc
      try {
        final countRes = await _dio.get('/api/training_department/notifications/unread-count');
        _unreadCount = (countRes.data['count'] as num?)?.toInt() ?? 0;
      } catch (_) {
        _unreadCount = _items.where((n) => (n['status'] ?? 'UNREAD').toString().toUpperCase() == 'UNREAD').length;
      }
      
      _error = null;
    } on DioException catch (e) {
      _error = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? 'Không thể tải thông báo')
          : 'Không thể tải thông báo';
    } catch (e) {
      _error = 'Không thể tải thông báo';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _ensureAuthHeader();
      await _dio.post('/api/training_department/notifications/$id/read');
      await _fetch();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _ensureAuthHeader();
      await _dio.post('/api/training_department/notifications/mark-all-read');
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đánh dấu tất cả')),
        );
      }
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _ensureAuthHeader();
      await _dio.delete('/api/training_department/notifications/$id');
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa thông báo')),
        );
      }
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST_PENDING':
        return '🔔 Đơn xin nghỉ';
      case 'MAKEUP_REQUEST_PENDING':
        return '🔔 Đề xuất dạy bù';
      case 'LEAVE_RESPONSE':
        return '✅ Phản hồi đơn nghỉ';
      case 'MAKEUP_RESPONSE':
        return '✅ Phản hồi dạy bù';
      default:
        return '📬 Thông báo';
    }
  }

  Color _getNotificationColor(BuildContext context, String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST_PENDING':
      case 'MAKEUP_REQUEST_PENDING':
        return const Color(0xFF1A2EB0);
      case 'LEAVE_RESPONSE':
      case 'MAKEUP_RESPONSE':
        return const Color(0xFF46B285);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        
        // Header với số thông báo chưa đọc
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  if (_unreadCount > 0)
                    Text(
                      '$_unreadCount chưa đọc',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A2EB0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (_unreadCount > 0)
                ElevatedButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Đánh dấu tất cả'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2EB0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        
        // Nội dung
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có thông báo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (context, index) {
                                final n = _items[index];
                                final id = n['id'] as int?;
                                final title = (n['title'] ?? '').toString();
                                final body = (n['body'] ?? '').toString();
                                final type = (n['type'] ?? '').toString();
                                final status = (n['status'] ?? 'UNREAD').toString();
                                final createdAt = (n['created_at'] ?? '').toString();
                                final fromUser = n['from_user'] is Map
                                    ? Map<String, dynamic>.from(n['from_user'])
                                    : null;
                                final fromUserName = fromUser?['name']?.toString() ?? '';
                                final isUnread = status.toUpperCase() == 'UNREAD';

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUnread
                                        ? const Color(0xFFF0F4FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isUnread
                                          ? const Color(0xFF1A2EB0).withOpacity(0.3)
                                          : Colors.grey[300]!,
                                      width: isUnread ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _getNotificationColor(context, type),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isUnread
                                            ? Icons.notifications_active
                                            : Icons.notifications_none,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: isUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Mới',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (type.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6, bottom: 6),
                                            child: Text(
                                              _getNotificationTypeLabel(type),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _getNotificationColor(context, type),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        if (body.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Text(
                                              body,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF545454),
                                              ),
                                            ),
                                          ),
                                        if (fromUserName.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  fromUserName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (createdAt.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                createdAt,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    onTap: id == null || !isUnread ? null : () => _markRead(id),
                                    trailing: id == null
                                        ? null
                                        : PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            itemBuilder: (context) => [
                                              if (isUnread)
                                                const PopupMenuItem(
                                                  value: 'mark_read',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.done, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Đánh dấu đã đọc'),
                                                    ],
                                                  ),
                                                ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Xóa', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'mark_read') {
                                                _markRead(id);
                                              } else if (value == 'delete') {
                                                _delete(id);
                                              }
                                            },
                                          ),
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 4),
                              itemCount: _items.length,
                            ),
                    ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(_error ?? 'Đã xảy ra lỗi.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2EB0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
