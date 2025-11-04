import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/attendance/model/entities/attendance_record.dart';

typedef AttendanceResult = Result<void, Exception>;

abstract class AttendanceRepository {
  Future<AttendanceResult> submitAttendance(List<AttendanceRecord> records);
}
