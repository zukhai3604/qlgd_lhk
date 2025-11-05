import 'package:qlgd_lhk/common/utils/result.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/api/schedule_api.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/models/schedule_item.dart';

typedef ScheduleResult<T> = Result<T, Exception>;

class FilterOption {
  final String value;
  final String label;
  final Map<String, dynamic>? extra;

  const FilterOption({
    required this.value,
    required this.label,
    this.extra,
  });
}

class WeeklyScheduleResult {
  final List<ScheduleItem> items;
  final List<FilterOption> semesters;
  final List<FilterOption> weeks;
  final String? selectedSemesterId;
  final String? selectedWeekValue;
  final DateTime? weekStart;
  final DateTime? weekEnd;

  const WeeklyScheduleResult({
    required this.items,
    required this.semesters,
    required this.weeks,
    this.selectedSemesterId,
    this.selectedWeekValue,
    this.weekStart,
    this.weekEnd,
  });
}

/// Repository cho weekly schedule
abstract class ScheduleRepository {
  Future<ScheduleResult<WeeklyScheduleResult>> getWeeklySchedule({
    String? semesterId,
    String? weekValue,
  });
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleApi _api;

  ScheduleRepositoryImpl({ScheduleApi? api}) : _api = api ?? ScheduleApi();

  @override
  Future<ScheduleResult<WeeklyScheduleResult>> getWeeklySchedule({
    String? semesterId,
    String? weekValue,
  }) async {
    try {
      dynamic root;
      var legacyMode = false;

      try {
        final data = await _api.getSchedule(
          semesterId: semesterId,
          weekValue: weekValue,
        );
        root = data;
      } catch (e) {
        if (_isRouteMissing(e)) {
          legacyMode = true;
          final weekData = await _api.getWeek(
            date: weekValue != null && weekValue.isNotEmpty
                ? _extractDateFromWeekValue(weekValue)
                : null,
          );
          root = weekData;
        } else {
          rethrow;
        }
      }

      final dataList = legacyMode
          ? (root is List ? root : const [])
          : _extractList(root, ['data', 'items']);

      final items = dataList
          .whereType<Map>()
          .map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final filtersMap =
          legacyMode ? null : _findMap(root, ['filters', 'meta', 'options']);
      final semestersRaw = legacyMode
          ? const []
          : _extractList(filtersMap, ['semesters', 'semester', 'semester_list']);
      final weeksRaw = legacyMode
          ? const []
          : _extractList(filtersMap, ['weeks', 'week', 'week_list']);

      final semesters = semestersRaw
          .whereType<Map>()
          .map(
            (e) => FilterOption(
              value: '${e['value'] ?? e['id'] ?? e['code'] ?? ''}',
              label: '${e['label'] ?? e['name'] ?? e['title'] ?? ''}',
              extra: Map<String, dynamic>.from(e),
            ),
          )
          .where((e) => e.value.isNotEmpty)
          .toList();

      final weeks = weeksRaw
          .whereType<Map>()
          .map(
            (e) => FilterOption(
              value: '${e['value'] ?? e['id'] ?? e['code'] ?? ''}',
              label: '${e['label'] ?? e['name'] ?? e['title'] ?? ''}',
              extra: Map<String, dynamic>.from(e),
            ),
          )
          .where((e) => e.value.isNotEmpty)
          .toList();

      String? selectedSemester;
      String? selectedWeek;
      DateTime? weekStart;
      DateTime? weekEnd;

      final map = filtersMap;
      if (map != null) {
        selectedSemester = map['selected_semester'] ?? map['semester_id'];
        selectedWeek = map['selected_week'] ?? map['week'];

        String? parseString(dynamic v) => v == null ? null : '$v';

        DateTime? parseDate(dynamic v) {
          if (v == null) return null;
          if (v is DateTime) return v;
          if (v is int) {
            return DateTime.fromMillisecondsSinceEpoch(v);
          }
          if (v is String) {
            return DateTime.tryParse(v);
          }
          return null;
        }

        weekStart = parseDate(map['week_start'] ?? map['from'] ?? map['start']);
        weekEnd = parseDate(map['week_end'] ?? map['to'] ?? map['end']);

        selectedSemester = parseString(selectedSemester);
        selectedWeek = parseString(selectedWeek);
      }

      return ScheduleResult.success(
        WeeklyScheduleResult(
          items: items,
          semesters: semesters,
          weeks: weeks,
          selectedSemesterId: legacyMode ? null : selectedSemester,
          selectedWeekValue: legacyMode ? null : selectedWeek,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
      );
    } catch (e) {
      return ScheduleResult.failure(
        Exception('Không tải được lịch giảng dạy: $e'),
      );
    }
  }

  List<dynamic> _extractList(dynamic source, List<String> keys) {
    if (source is List) return source;
    if (source is Map) {
      for (final key in keys) {
        final value = source[key];
        if (value is List) return value;
      }
    }

    if (source is Map) {
      for (final entry in source.entries) {
        if (entry.value is Map || entry.value is List) {
          final result = _extractList(entry.value, keys);
          if (result.isNotEmpty) return result;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic>? _findMap(dynamic source, List<String> keys) {
    if (source is Map<String, dynamic>) {
      for (final key in keys) {
        final value = source[key];
        if (value is Map<String, dynamic>) return value;
      }
      for (final entry in source.entries) {
        if (entry.value is Map || entry.value is List) {
          final result = _findMap(entry.value, keys);
          if (result != null) return result;
        }
      }
    } else if (source is List) {
      for (final item in source) {
        final result = _findMap(item, keys);
        if (result != null) return result;
      }
    }
    return null;
  }

  bool _isRouteMissing(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('404') ||
          message.contains('could not be found') ||
          message.contains('not found')) {
        return true;
      }
    }
    return false;
  }

  String? _extractDateFromWeekValue(String weekValue) {
    final regex = RegExp(r'(\d{4}-\d{2}-\d{2})');
    final match = regex.firstMatch(weekValue);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
}

