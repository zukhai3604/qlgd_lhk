import 'package:dio/dio.dart';
import '../core/api_client.dart';

class NotificationsService {
  NotificationsService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<Map<String, dynamic>> list({bool? isRead, int page = 1}) async {
    final res = await _dio.get(
      '/api/lecturer/notifications',
      queryParameters: {
        if (isRead != null) 'is_read': isRead,
        'page': page,
      },
    );

    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : {};
    final items = (data['data'] as List?)?.cast<dynamic>() ?? const [];
    final list = items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final meta = data['meta'] is Map
        ? Map<String, dynamic>.from(data['meta'])
        : <String, dynamic>{};
    return {'data': list, 'meta': meta};
  }

  Future<void> markRead(int id) async {
    await _dio.post('/api/lecturer/notifications/$id/read');
  }

  Future<void> delete(int id) async {
    await _dio.delete('/api/lecturer/notifications/$id');
  }
}

