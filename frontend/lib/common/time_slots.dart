import 'package:intl/intl.dart';

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange(this.start, this.end);

  String label() {
    final fmt = DateFormat('HH:mm');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }
}

DateTime _clamp(DateTime d, int h, int m) =>
    DateTime(d.year, d.month, d.day, h, m);

/// Sinh danh sách “tiết” trong 1 ngày theo:
/// - Khung 07:00 → 21:30
/// - Tiết 50’, nghỉ 5’
/// - Ngoại lệ: 12:25→12:55 và 18:20→18:50
List<TimeRange> generateTeachingPeriods(DateTime day) {
  final startDay = _clamp(day, 7, 0);
  final endDay = _clamp(day, 21, 30);

  const slot = Duration(minutes: 50);
  const shortBreak = Duration(minutes: 5);

  final periods = <TimeRange>[];
  DateTime cursor = startDay;

  bool isSameHM(DateTime d, int h, int m) => d.hour == h && d.minute == m;

  while (cursor.isBefore(endDay)) {
    final end = cursor.add(slot);
    if (end.isAfter(endDay)) break;

    periods.add(TimeRange(cursor, end));

    var nextStart = end.add(shortBreak);
    if (isSameHM(end, 12, 25)) {
      nextStart = _clamp(day, 12, 55);
    } else if (isSameHM(end, 18, 20)) {
      nextStart = _clamp(day, 18, 50);
    }

    if (!nextStart.isBefore(endDay)) break;
    cursor = nextStart;
  }

  return periods;
}

/// Tạo mốc nhãn giờ (07:00, 08:00, ..., 21:30)
List<DateTime> generateHourTicks(DateTime day) {
  final end = _clamp(day, 21, 30);
  final ticks = <DateTime>[];

  DateTime cursor = _clamp(day, 7, 0);
  while (!cursor.isAfter(end)) {
    ticks.add(cursor);
    cursor = cursor.add(const Duration(hours: 1));
  }

  if (ticks.isEmpty || ticks.last != end) {
    ticks.add(end);
  }

  return ticks;
}
