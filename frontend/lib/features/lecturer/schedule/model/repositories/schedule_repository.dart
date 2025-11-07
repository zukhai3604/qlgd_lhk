import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/schedule/model/entities/schedule_entry.dart';

typedef ScheduleResult = Result<List<ScheduleEntry>, Exception>;

abstract class ScheduleRepository {
  Future<ScheduleResult> getSchedule();
}
