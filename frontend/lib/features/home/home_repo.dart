import 'package:qlgd_lhk/core/api_client.dart';
import 'package:qlgd_lhk/core/models.dart';

class LecturerHomeRepo {
  final _api = ApiClient.create();

  Future<User> me() async {
    final r = await _api.dio.get('/me');
    return User.fromJson(r.data as Map<String,dynamic>);
  }

  Future<List<ScheduleItem>> week(DateTime anyDate) async {
    final dateStr = anyDate.toIso8601String().substring(0,10); // YYYY-MM-DD
    final r = await _api.dio.get('/lecturer/schedule/week', queryParameters: {'date': dateStr});
    final data = (r.data is Map && (r.data as Map).containsKey('data')) ? (r.data['data'] as List) : (r.data as List);
    return data.map((e)=>ScheduleItem.fromJson(e as Map<String,dynamic>)).toList();
  }
}
