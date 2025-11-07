import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/schedule/model/datasources/schedule_remote_ds.dart';
import 'package:qlgd_lhk/features/schedule/model/entities/schedule_entry.dart';
import 'package:qlgd_lhk/features/schedule/model/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDS _remoteDataSource;

  ScheduleRepositoryImpl(this._remoteDataSource);

  @override
  Future<ScheduleResult> getSchedule() async {
    // Mock implementation
    return Result.success([]);
  }
}
