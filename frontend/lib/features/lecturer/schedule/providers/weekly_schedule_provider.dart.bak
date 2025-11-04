import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api_client.dart';
import '../models/schedule_item.dart';

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

class WeeklyScheduleQuery {
  final String? semesterId;
  final String? weekValue;

  const WeeklyScheduleQuery({
    this.semesterId,
    this.weekValue,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (semesterId != null && semesterId!.isNotEmpty) {
      params['semester_id'] = semesterId;
    }
    if (weekValue != null && weekValue!.isNotEmpty) {
      params['week'] = weekValue;
    }
    return params;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyScheduleQuery &&
          runtimeType == other.runtimeType &&
          semesterId == other.semesterId &&
          weekValue == other.weekValue;

  @override
  int get hashCode => Object.hash(semesterId, weekValue);
}

final weeklyScheduleProvider =
    FutureProvider.family<WeeklyScheduleResult, WeeklyScheduleQuery>(
        (ref, query) async {
  final dio = ApiClient().dio;

  dynamic root;
  var legacyMode = false;

  try {
    final res = await dio.get(
      '/api/lecturer/schedule',
      queryParameters: query.toQueryParameters(),
    );
    root = res.data;
  } on DioException catch (e) {
    if (_isRouteMissing(e)) {
      legacyMode = true;
      final fallbackRes = await dio.get(
        '/api/lecturer/schedule/week',
        queryParameters: _legacyQueryFrom(query),
      );
      root = fallbackRes.data;
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

  return WeeklyScheduleResult(
    items: items,
    semesters: semesters,
    weeks: weeks,
    selectedSemesterId: legacyMode ? null : selectedSemester,
    selectedWeekValue: legacyMode ? null : selectedWeek,
    weekStart: weekStart,
    weekEnd: weekEnd,
  );
});

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

bool _isRouteMissing(DioException error) {
  final status = error.response?.statusCode;
  if (status == 404) return true;
  if (status == 500 && error.response?.data is Map) {
    final map = error.response!.data as Map;
    final message = map['message']?.toString() ?? '';
    final debug = map['debug'];
    if (message.contains('could not be found')) return true;
    if (debug is Map) {
      final debugMessage = debug['message']?.toString() ?? '';
      if (debugMessage.contains('could not be found')) return true;
    }
  }
  return false;
}

Map<String, dynamic> _legacyQueryFrom(WeeklyScheduleQuery query) {
  if (query.weekValue == null || query.weekValue!.isEmpty) {
    return {};
  }

  final raw = query.weekValue!;
  final regex = RegExp(r'(\d{4}-\d{2}-\d{2})');
  final match = regex.firstMatch(raw);
  if (match != null) {
    return {'date': match.group(1)};
  }

  return {};
}
