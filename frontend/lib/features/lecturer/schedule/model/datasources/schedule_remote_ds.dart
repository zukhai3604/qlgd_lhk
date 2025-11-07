import 'package:qlgd_lhk/features/schedule/model/dtos/schedule_dto.dart';

abstract class ScheduleRemoteDS {
  Future<List<ScheduleDto>> getSchedule();
}

class ScheduleRemoteDSImpl implements ScheduleRemoteDS {
  @override
  Future<List<ScheduleDto>> getSchedule() async {
    // Mock remote data source
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }
}
