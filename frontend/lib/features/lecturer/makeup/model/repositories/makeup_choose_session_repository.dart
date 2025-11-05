import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/api/makeup_api.dart';

typedef MakeupChooseSessionResult<T> = Result<T, Exception>;

/// Repository cho makeup choose session
abstract class MakeupChooseSessionRepository {
  Future<MakeupChooseSessionResult<List<Map<String, dynamic>>>> getApprovedLeaves();
}

/// Implementation của MakeupChooseSessionRepository
class MakeupChooseSessionRepositoryImpl implements MakeupChooseSessionRepository {
  final LecturerMakeupApi _api;

  MakeupChooseSessionRepositoryImpl({LecturerMakeupApi? api}) : _api = api ?? LecturerMakeupApi();

  @override
  Future<MakeupChooseSessionResult<List<Map<String, dynamic>>>> getApprovedLeaves() async {
    try {
      // Lấy trang đầu tiên
      final firstPage = await _api.approvedLeaves(page: 1);
      
      // Nếu có nhiều trang, fetch thêm (tạm thời chỉ lấy trang 1)
      final allLeaves = <Map<String, dynamic>>[];
      allLeaves.addAll(firstPage);
      
      // TODO: Nếu cần pagination, có thể fetch thêm các trang tiếp theo
      
      return MakeupChooseSessionResult.success(allLeaves);
    } catch (e) {
      return MakeupChooseSessionResult.failure(Exception('Không tải được danh sách đơn nghỉ đã duyệt: $e'));
    }
  }
}

