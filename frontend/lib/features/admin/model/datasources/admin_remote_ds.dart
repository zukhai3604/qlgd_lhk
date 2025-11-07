import 'package:dio/dio.dart' as dio;
import '../../../../core/api_client.dart';

class AdminRemoteDs {
  final dio.Dio _dioClient;

  AdminRemoteDs({dio.Dio? dioClient})
      : _dioClient = dioClient ?? ApiClient.create().dio;

  // GET /admin/users?page=&search=
  Future<Map<String, dynamic>> listUsers({int page = 1, String? search}) async {
    final res = await _dioClient.get('/admin/users', queryParameters: {
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (res.data is Map ? res.data as Map : {}).cast<String, dynamic>();
  }

  // GET /admin/users/{id}
  Future<Map<String, dynamic>> getUser(int id) async {
    final res = await _dioClient.get('/admin/users/$id');
    return (res.data is Map ? res.data as Map : {}).cast<String, dynamic>();
  }

  // /admin/users/{id}/lock & /unlock (một số backend dùng GET, số khác dùng POST/PUT)
  Future<void> lockUser(int id) async {
    await _dioClient.request('/admin/users/$id/lock', options: dio.Options(method: 'POST'));
  }

  Future<void> unlockUser(int id) async {
    await _dioClient.request('/admin/users/$id/unlock', options: dio.Options(method: 'POST'));
  }

  // GET /admin/dashboard/stats
  Future<Map<String, dynamic>> getStats() async {
    final res = await _dioClient.get('/admin/dashboard/stats');
    return (res.data is Map ? res.data as Map : {}).cast<String, dynamic>();
  }

  // GET /admin/reports/system
  Future<Map<String, dynamic>> systemReport() async {
    final res = await _dioClient.get('/admin/reports/system');
    return (res.data is Map ? res.data as Map : {}).cast<String, dynamic>();
  }
}
