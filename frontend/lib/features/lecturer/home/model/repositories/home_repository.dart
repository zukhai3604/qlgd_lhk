import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';

typedef HomeResult<T> = Result<T, Exception>;

/// Repository cho home page - quản lý logic lấy dữ liệu
abstract class HomeRepository {
  Future<HomeResult<Map<String, dynamic>>> getTodaySchedule(String date);
  Future<HomeResult<Map<String, dynamic>>> getStats();
}

/// Implementation của HomeRepository
class HomeRepositoryImpl implements HomeRepository {
  final ScheduleApi _scheduleApi;

  HomeRepositoryImpl({ScheduleApi? scheduleApi})
      : _scheduleApi = scheduleApi ?? ScheduleApi();

  @override
  Future<HomeResult<Map<String, dynamic>>> getTodaySchedule(String date) async {
    try {
      final response = await _scheduleApi.getWeek(date: date);
      final List raw = (response['data'] as List?) ?? const [];
      final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Filter theo ngày
      bool isSameDay(dynamic d) {
        final s = (d ?? '').toString();
        final only = s.split(' ').first;
        return only == date;
      }

      final todaySchedule = list.where((x) => isSameDay(x['date'])).toList();

      // Sort theo start_time
      todaySchedule.sort((a, b) =>
          (a['start_time'] ?? '').toString().compareTo((b['start_time'] ?? '').toString()));

      return HomeResult.success({
        'schedule': todaySchedule,
        'date': date,
      });
    } catch (e) {
      return HomeResult.failure(Exception('Không tải được lịch giảng dạy: $e'));
    }
  }

  @override
  Future<HomeResult<Map<String, dynamic>>> getStats() async {
    try {
      final response = await _scheduleApi.getStats();
      final data = response['data'] is Map 
          ? Map<String, dynamic>.from(response['data']) 
          : <String, dynamic>{};
      final semester = response['semester'] is Map
          ? Map<String, dynamic>.from(response['semester'])
          : null;
      
      return HomeResult.success({
        ...data,
        'semester': semester,
      });
    } catch (e) {
      return HomeResult.failure(Exception('Không tải được thống kê: $e'));
    }
  }
}

