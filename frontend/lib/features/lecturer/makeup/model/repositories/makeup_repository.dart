import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/api/makeup_api.dart';

typedef MakeupResult<T> = Result<T, Exception>;

/// Repository cho makeup operations
abstract class MakeupRepository {
  Future<MakeupResult<List<Map<String, dynamic>>>> getRooms();
  Future<MakeupResult<Map<int, int>>> getTimeslotIdMap({
    required DateTime selectedDate,
    required List<int> periods,
  });
  Future<MakeupResult<void>> createMakeupRequest(Map<String, dynamic> payload);
  Future<MakeupResult<void>> createMultipleMakeupRequests(List<Map<String, dynamic>> payloads);
}

/// Implementation của MakeupRepository
class MakeupRepositoryImpl implements MakeupRepository {
  final LecturerMakeupApi _api;

  MakeupRepositoryImpl({LecturerMakeupApi? api}) : _api = api ?? LecturerMakeupApi();

  @override
  Future<MakeupResult<List<Map<String, dynamic>>>> getRooms() async {
    try {
      final rooms = await _api.getRooms();
      return MakeupResult.success(rooms);
    } catch (e) {
      return MakeupResult.failure(Exception('Không thể tải danh sách phòng: $e'));
    }
  }

  @override
  Future<MakeupResult<Map<int, int>>> getTimeslotIdMap({
    required DateTime selectedDate,
    required List<int> periods,
  }) async {
    try {
      final map = <int, int>{};
      
      for (final period in periods) {
        // Convert Dart weekday (1=Mon, 7=Sun) to Laravel day_of_week (1=Sun, 2=Mon, ..., 7=Sat)
        final dayOfWeek = selectedDate.weekday == 7 ? 1 : selectedDate.weekday + 1;
        
        try {
          final timeslotId = await _api.getTimeslotIdByPeriod(dayOfWeek, period);
          if (timeslotId != null) {
            map[period] = timeslotId;
          }
        } catch (_) {
          // Skip periods that don't have timeslots
        }
      }
      
      return MakeupResult.success(map);
    } catch (e) {
      return MakeupResult.failure(Exception('Không thể lấy thông tin timeslot: $e'));
    }
  }

  @override
  Future<MakeupResult<void>> createMakeupRequest(Map<String, dynamic> payload) async {
    try {
      await _api.create(payload);
      return MakeupResult.success(null);
    } catch (e) {
      return MakeupResult.failure(Exception('Không thể tạo đơn đăng ký dạy bù: $e'));
    }
  }

  @override
  Future<MakeupResult<void>> createMultipleMakeupRequests(List<Map<String, dynamic>> payloads) async {
    try {
      int successCount = 0;
      String? lastError;

      for (final payload in payloads) {
        try {
          await _api.create(payload);
          successCount++;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (successCount == payloads.length) {
        return MakeupResult.success(null);
      } else if (successCount > 0) {
        return MakeupResult.failure(
          Exception('Đã gửi $successCount/${payloads.length} đăng ký. Lỗi: ${lastError ?? "Không xác định"}'),
        );
      } else {
        return MakeupResult.failure(
          Exception('Gửi đăng ký thất bại: ${lastError ?? "Không xác định"}'),
        );
      }
    } catch (e) {
      return MakeupResult.failure(Exception('Không thể tạo đơn đăng ký dạy bù: $e'));
    }
  }
}

