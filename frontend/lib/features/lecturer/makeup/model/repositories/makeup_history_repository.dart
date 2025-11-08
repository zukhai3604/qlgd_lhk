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
      // ✅ Giữ nguyên error message từ API (đã được extract)
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      return MakeupHistoryResult.failure(Exception(errorMsg));
    }
  }

  @override
  Future<MakeupHistoryResult<void>> cancelMultipleMakeupRequests(List<int> makeupRequestIds) async {
    try {
      print('DEBUG MakeupHistoryRepository: cancelMultipleMakeupRequests called with IDs: $makeupRequestIds');
      int successCount = 0;
      String? lastError;

      for (final makeupRequestId in makeupRequestIds) {
        try {
          print('DEBUG MakeupHistoryRepository: Canceling makeup request ID: $makeupRequestId');
          await _api.cancel(makeupRequestId);
          print('DEBUG MakeupHistoryRepository: Successfully canceled makeup request ID: $makeupRequestId');
          successCount++;
        } catch (e, stackTrace) {
          // ✅ Extract error message từ exception
          print('DEBUG MakeupHistoryRepository: Error canceling makeup request ID $makeupRequestId: $e');
          print('DEBUG MakeupHistoryRepository: StackTrace: $stackTrace');
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          lastError = errorMsg;
        }
      }

      print('DEBUG MakeupHistoryRepository: cancelMultipleMakeupRequests result: successCount=$successCount/${makeupRequestIds.length}, lastError=$lastError');

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
    } catch (e, stackTrace) {
      // ✅ Giữ nguyên error message từ API
      print('DEBUG MakeupHistoryRepository: cancelMultipleMakeupRequests outer catch: $e');
      print('DEBUG MakeupHistoryRepository: StackTrace: $stackTrace');
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      return MakeupHistoryResult.failure(Exception(errorMsg));
    }
  }
}

