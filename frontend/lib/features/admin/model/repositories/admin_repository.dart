import 'package:dio/dio.dart';
import '../datasources/admin_remote_ds.dart';

class AdminRepository {
  final AdminRemoteDs _ds;

  // Accept optional Dio instance and pass it to AdminRemoteDs
  AdminRepository({Dio? dio, AdminRemoteDs? ds})
      : _ds = ds ?? AdminRemoteDs(dioClient: dio);

  Future<List<Map<String, dynamic>>> users({int page = 1, String? search}) async {
    final json = await _ds.listUsers(page: page, search: search);
    final data = (json['data'] ?? json) as Object?;
    if (data is List) return data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
    // Bạn có thể đọc meta nếu backend trả về pagination.
  }

  Future<Map<String, dynamic>> user(int id) async {
    final json = await _ds.getUser(id);
    final data = (json['data'] ?? json);
    return (data as Map).cast<String, dynamic>();
  }

  Future<void> lock(int id) => _ds.lockUser(id);
  Future<void> unlock(int id) => _ds.unlockUser(id);

  Future<Map<String, dynamic>> stats() => _ds.getStats();
  Future<Map<String, dynamic>> report() => _ds.systemReport();

  // Alias methods for AdminViewModel compatibility
  Future<Map<String, dynamic>> getDashboardStats() => stats();
  Future<Map<String, dynamic>> fetchUsers({int page = 1, String? search}) async {
    return await _ds.listUsers(page: page, search: search);
  }
  Future<void> lockUser(String id) => lock(int.parse(id));
  Future<void> unlockUser(String id) => unlock(int.parse(id));
}
