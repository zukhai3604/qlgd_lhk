// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import '../models/schedule_item.dart';
import '../providers/weekly_schedule_provider.dart';

const List<Map<String, String>> _periods = [
  {'start': '07:00', 'end': '07:50'},
  {'start': '07:55', 'end': '08:45'},
  {'start': '08:50', 'end': '09:40'},
  {'start': '09:45', 'end': '10:35'},
  {'start': '10:40', 'end': '11:30'},
  {'start': '11:35', 'end': '12:25'},
  {'start': '12:55', 'end': '13:45'},
  {'start': '13:50', 'end': '14:40'},
  {'start': '14:45', 'end': '15:35'},
  {'start': '15:40', 'end': '16:30'},
  {'start': '16:35', 'end': '17:25'},
  {'start': '17:30', 'end': '18:20'},
  {'start': '18:50', 'end': '19:40'},
  {'start': '19:45', 'end': '20:35'},
  {'start': '20:40', 'end': '21:30'},
];

const double kRowHeight = 84;
const double kMinEventHeight = 68;
const double _dayColumnWidth = 132;
const double _timelineWidth = 108;
const double _headerHeight = 68;
const double _headerGap = 12;
final double _gridHeight = _periods.length * kRowHeight;

const List<Color> _palette = [
  Color(0xFF0D47A1),
  Color(0xFF00695C),
  Color(0xFF6A1B9A),
  Color(0xFFEF6C00),
  Color(0xFF00838F),
  Color(0xFF8E24AA),
  Color(0xFF2E7D32),
  Color(0xFF4527A0),
  Color(0xFFAD1457),
  Color(0xFF1565C0),
  Color(0xFF558B2F),
  Color(0xFFD84315),
];

Color _seededColor(String key) {
  var hash = 0;
  for (final rune in key.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return _palette[hash % _palette.length];
}

String _normHHmm(dynamic value) {
  if (value == null) return '--:--';
  if (value is DateTime) return DateFormat('HH:mm', 'vi').format(value);
  var text = value.toString().trim();
  if (text.isEmpty) return '--:--';
  if (text.contains(' ')) text = text.split(' ').last;
  if (text.contains('T')) text = text.split('T').last;
  text = text.replaceAll(RegExp(r'[Zz]$'), '');
  if (text.contains('+')) text = text.split('+').first;
  if (text.contains('-') && text.indexOf('-') > 2) {
    text = text.split('-').first;
  }
  if (text.length >= 5) text = text.substring(0, 5);
  final parts = text.split(':');
  if (parts.length >= 2) {
    final hh = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    return '$hh:$mm';
  }
  return '--:--';
}

int _hhmmToMin(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return h * 60 + m;
}

int? _detectPeriodExact(String start, String end, {int toleranceMinutes = 2}) {
  final startMin = _hhmmToMin(start);
  final endMin = _hhmmToMin(end);
  for (var i = 0; i < _periods.length; i++) {
    final ps = _hhmmToMin(_periods[i]['start']!);
    final pe = _hhmmToMin(_periods[i]['end']!);
    if ((startMin - ps).abs() <= toleranceMinutes &&
        (endMin - pe).abs() <= toleranceMinutes) {
      return i + 1;
    }
  }
  return null;
}

int _nearestStartIndex(String start) {
  final startMin = _hhmmToMin(start);
  var bestIndex = 0;
  var bestDiff = 1 << 30;
  for (var i = 0; i < _periods.length; i++) {
    final ps = _hhmmToMin(_periods[i]['start']!);
    final diff = (startMin - ps).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      bestIndex = i;
    }
  }
  return bestIndex + 1;
}

int _nearestEndIndex(String end) {
  final endMin = _hhmmToMin(end);
  var bestIndex = 0;
  var bestDiff = 1 << 30;
  for (var i = 0; i < _periods.length; i++) {
    final pe = _hhmmToMin(_periods[i]['end']!);
    final diff = (endMin - pe).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      bestIndex = i;
    }
  }
  return bestIndex + 1;
}

double _topOfPeriod(int index) => (index - 1) * kRowHeight;

double _heightBySpan(int startIndex, int endIndex) {
  final rows = math.max(1, endIndex - startIndex + 1);
  return rows * kRowHeight;
}

typedef DayTapCallback = void Function(DateTime day, List<ScheduleItem> events);

class WeeklySchedulePage extends ConsumerStatefulWidget {
  const WeeklySchedulePage({super.key});
  @override
  ConsumerState<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends ConsumerState<WeeklySchedulePage> {
  WeeklyScheduleQuery _query = const WeeklyScheduleQuery();
  String? _semesterId;
  String? _weekValue;
  DateTime? _weekStart;
  DateTime? _weekEnd;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(weeklyScheduleProvider(_query));
    asyncValue.whenData((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var shouldSetState = false;

        final incomingSemester = value.selectedSemesterId ??
            (value.semesters.isNotEmpty ? value.semesters.first.value : null);
        if (_semesterId == null && incomingSemester != null) {
          _semesterId = incomingSemester;
          shouldSetState = true;
        }

        final incomingWeek = value.selectedWeekValue ??
            (value.weeks.isNotEmpty ? value.weeks.first.value : null);
        if (_weekValue == null && incomingWeek != null) {
          _weekValue = incomingWeek;
          shouldSetState = true;
        }

        final newWeekStart = value.weekStart;
        if (newWeekStart != null &&
            (_weekStart == null || !_isSameDay(newWeekStart, _weekStart!))) {
          _weekStart = newWeekStart;
          shouldSetState = true;
        }

        final newWeekEnd = value.weekEnd;
        if (newWeekEnd != null &&
            (_weekEnd == null || !_isSameDay(newWeekEnd, _weekEnd!))) {
          _weekEnd = newWeekEnd;
          shouldSetState = true;
        }

        final desiredSemester = _semesterId ?? incomingSemester;
        final desiredWeek = _weekValue ?? incomingWeek;
        if (_query.semesterId != desiredSemester ||
            _query.weekValue != desiredWeek) {
          _query = WeeklyScheduleQuery(
            semesterId: desiredSemester,
            weekValue: desiredWeek,
          );
          shouldSetState = true;
        }

        if (shouldSetState) {
          setState(() {});
        }
      });
    });

    return Scaffold(
      appBar: const TluAppBar(),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.refresh(weeklyScheduleProvider(_query)),
        ),
        data: (data) {
          final items = data.items;
          final weekStart = _deriveWeekStart(data, items);
          final days = List<DateTime>.generate(
            7,
            (index) => weekStart.add(Duration(days: index)),
          );
          final grouped = _groupByDay(items);
          final headerRange = _buildHeaderRange(weekStart);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(weeklyScheduleProvider(_query));
              await ref.read(weeklyScheduleProvider(_query).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'Lịch giảng dạy',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (headerRange != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    headerRange,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                _DropdownFilter(
                  label: 'Học kỳ',
                  value: _semesterId,
                  options: data.semesters,
                  onChanged: (value) {
                    setState(() {
                      _semesterId = value;
                      _weekValue = null;
                      _weekStart = null;
                      _weekEnd = null;
                      _query = WeeklyScheduleQuery(
                        semesterId: value,
                        weekValue: _weekValue,
                      );
                    });
                  },
                ),
                const SizedBox(height: 12),
                _DropdownFilter(
                  label: 'Tuần',
                  value: _weekValue,
                  options: data.weeks,
                  onChanged: (value) {
                    setState(() {
                      _weekValue = value;
                      _weekStart = null;
                      _weekEnd = null;
                      _query = WeeklyScheduleQuery(
                        semesterId: _semesterId,
                        weekValue: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 24),
                _TimelineGrid(
                  days: days,
                  groupedItems: grouped,
                  onDayTap: (day, events) =>
                      _showDaySchedule(context, day, events),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<DateTime, List<ScheduleItem>> _groupByDay(List<ScheduleItem> items) {
    final map = <DateTime, List<ScheduleItem>>{};
    for (final item in items) {
      final key = DateTime(
        item.startTime.year,
        item.startTime.month,
        item.startTime.day,
      );
      map.putIfAbsent(key, () => <ScheduleItem>[]).add(item);
    }
    for (final bucket in map.values) {
      bucket.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  DateTime _deriveWeekStart(
    WeeklyScheduleResult data,
    List<ScheduleItem> items,
  ) {
    if (_weekStart != null) return _weekStart!;
    if (data.weekStart != null) return data.weekStart!;
    if (items.isNotEmpty) {
      final first = items.first.startTime;
      return first.subtract(Duration(days: first.weekday - DateTime.monday));
    }
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - DateTime.monday));
  }

  String? _buildHeaderRange(DateTime weekStart) {
    final end = _weekEnd ?? weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('dd/MM/yyyy');
    return '${fmt.format(weekStart)} - ${fmt.format(end)}';
  }

  void _showDaySchedule(
    BuildContext context,
    DateTime day,
    List<ScheduleItem> events,
  ) {
    final titleRaw = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(day);
    final title = titleRaw.isEmpty
        ? ''
        : titleRaw[0].toUpperCase() + titleRaw.substring(1);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('Không có lịch trong ngày này'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }

        final sheetMaxHeight = MediaQuery.of(ctx).size.height * .6;
        final estimatedHeight = events.length * 84.0;
        final sheetHeight =
            estimatedHeight.clamp(220.0, sheetMaxHeight).toDouble();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: sheetHeight,
                  child: ListView.separated(
                    itemBuilder: (listContext, index) {
                      final item = events[index];
                      final color =
                          _seededColor('${item.subject}|${item.className}');
                      final start = _normHHmm(item.startTime);
                      final end = _normHHmm(item.endTime);
                      final timeRange = '$start - $end';
                      final room =
                          item.room.isEmpty ? 'Chưa cập nhật' : item.room;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 8,
                          backgroundColor: color,
                        ),
                        title: Text(
                          item.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Lớp: ${item.className}\n$timeRange • Phòng: $room',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => context.push(
                          '/schedule/class/${item.id}',
                          extra: item,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemCount: events.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String? value;
  final List<FilterOption> options;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: options.any((o) => o.value == value) ? value : null,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TimelineGrid extends StatelessWidget {
  final List<DateTime> days;
  final Map<DateTime, List<ScheduleItem>> groupedItems;
  final DayTapCallback onDayTap;

  const _TimelineGrid({
    required this.days,
    required this.groupedItems,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: _gridHeight + _headerHeight + _headerGap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TimelineColumn(),
            const SizedBox(width: 12),
            for (final day in days)
              _DayColumn(
                day: day,
                events: groupedItems[DateTime(day.year, day.month, day.day)] ??
                    const [],
                onTap: onDayTap,
              ),
            Container(
              width: 1,
              height: _gridHeight + _headerHeight + _headerGap,
              color: colorScheme.outlineVariant.withOpacity(.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _timelineWidth,
      child: Column(
        children: [
          const SizedBox(height: _headerHeight),
          const SizedBox(height: _headerGap),
          Container(
            height: _gridHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceVariant.withOpacity(.35),
            ),
            child: Column(
              children: List.generate(_periods.length, (index) {
                final period = _periods[index];
                return Container(
                  height: kRowHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(.35),
                        width: index == _periods.length - 1 ? 0 : 1,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Tiết ${index + 1}\n${period['start']} - ${period['end']}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final List<ScheduleItem> events;
  final DayTapCallback onTap;

  const _DayColumn({
    required this.day,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('dd', 'vi').format(day);
    final dowLabel = DateFormat.E('vi').format(day).toUpperCase();
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final eventsForDay = events;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: _dayColumnWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _headerHeight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTap(day, List.unmodifiable(eventsForDay)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dateLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dowLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: _headerGap),
            Container(
              height: _gridHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(.25),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: List.generate(_periods.length, (index) {
                          return Container(
                            height: kRowHeight,
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(.45),
                              border: Border(
                                bottom: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withOpacity(.35),
                                  width: index == _periods.length - 1 ? 0 : 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  for (final item in eventsForDay)
                    _EventBlock(item: item, highlight: isToday),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  final ScheduleItem item;
  final bool highlight;

  const _EventBlock({
    required this.item,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    var start = _normHHmm(item.startTime);
    var end = _normHHmm(item.endTime);
    if (start == '--:--') start = _periods.first['start']!;
    if (end == '--:--') end = start;

    final exactPeriod = _detectPeriodExact(start, end);
    var startIndex = exactPeriod ?? _nearestStartIndex(start);
    var endIndex = exactPeriod ?? _nearestEndIndex(end);
    startIndex = startIndex.clamp(1, _periods.length);
    endIndex = endIndex.clamp(startIndex, _periods.length);

    final top = _topOfPeriod(startIndex) + 6;
    final height =
        math.max(kMinEventHeight, _heightBySpan(startIndex, endIndex) - 12);

    final seed = '${item.subject}|${item.className}';
    final baseColor = _seededColor(seed);
    final backgroundColor =
        highlight ? baseColor.withOpacity(.20) : baseColor.withOpacity(.12);
    final borderColor =
        highlight ? baseColor.withOpacity(.70) : baseColor.withOpacity(.45);

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: height,
      child: GestureDetector(
        onTap: () => context.push('/schedule/class/${item.id}', extra: item),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: baseColor.withOpacity(.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Lớp: ${item.className}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
