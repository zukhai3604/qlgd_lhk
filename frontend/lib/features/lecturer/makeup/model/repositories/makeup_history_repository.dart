import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/api/makeup_api.dart';

typedef MakeupHistoryResult<T> = Result<T, Exception>;

/// Repository cho makeup history
abstract class MakeupHistoryRepository {
  Future<MakeupHistoryResult<List<Map<String, dynamic>>>> getMakeupRequests();
  Future<MakeupHistoryResult<void>> cancelMakeupRequest(int makeupRequestId);
  Future<MakeupHistoryResult<void>> cancelMultipleMakeupRequests(List<int> makeupRequestIds);
}

/// Implementation của MakeupHistoryRepository
class MakeupHistoryRepositoryImpl implements MakeupHistoryRepository {
  final LecturerMakeupApi _api;

  MakeupHistoryRepositoryImpl({LecturerMakeupApi? api}) : _api = api ?? LecturerMakeupApi();

  @override
  Future<MakeupHistoryResult<List<Map<String, dynamic>>>> getMakeupRequests() async {
    try {
      final list = await _api.list();
      return MakeupHistoryResult.success(list);
    } catch (e) {
      return MakeupHistoryResult.failure(Exception('Không tải được lịch sử đăng ký dạy bù: $e'));
    }
  }

  @override
  Future<MakeupHistoryResult<void>> cancelMakeupRequest(int makeupRequestId) async {
    try {
      await _api.cancel(makeupRequestId);
      return const MakeupHistoryResult.success(null);
    } catch (e) {
      return MakeupHistoryResult.failure(Exception('Hủy đơn thất bại: $e'));
    }
  }

  @override
  Future<MakeupHistoryResult<void>> cancelMultipleMakeupRequests(List<int> makeupRequestIds) async {
    try {
      int successCount = 0;
      String? lastError;

      for (final makeupRequestId in makeupRequestIds) {
        try {
          await _api.cancel(makeupRequestId);
          successCount++;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (successCount == makeupRequestIds.length) {
        return const MakeupHistoryResult.success(null);
      } else if (successCount > 0) {
        return MakeupHistoryResult.failure(
          Exception('Đã hủy $successCount/${makeupRequestIds.length} đơn. Lỗi: ${lastError ?? "Không xác định"}'),
        );
      } else {
        return MakeupHistoryResult.failure(
          Exception('Lỗi khi hủy: ${lastError ?? "Không xác định"}'),
        );
      }
    } catch (e) {
      return MakeupHistoryResult.failure(Exception('Lỗi khi hủy: $e'));
    }
  }
}

