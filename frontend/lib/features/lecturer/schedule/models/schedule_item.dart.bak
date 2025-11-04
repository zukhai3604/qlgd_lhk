import 'package:flutter/material.dart';

class ScheduleItem {
  final int id;
  final String subject;
  final String className;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final Map<String, dynamic> raw;

  ScheduleItem({
    required this.id,
    required this.subject,
    required this.className,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.raw,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return null;

        DateTime? parsed = DateTime.tryParse(trimmed);
        if (parsed != null) return parsed;

        final normalized = trimmed.replaceAll('T', ' ');
        parsed = DateTime.tryParse(normalized);
        if (parsed != null) return parsed;

        if (normalized.endsWith('Z')) {
          parsed =
              DateTime.tryParse(normalized.substring(0, normalized.length - 1));
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    DateTime? baseDate() {
      final candidates = [
        json['session_date'],
        json['sessionDate'],
        json['date'],
        json['day'],
        json['session_start'],
      ];
      for (final value in candidates) {
        final parsed = parseDate(value);
        if (parsed != null) return parsed;
      }
      return null;
    }

    DateTime? combineWithBase(DateTime? base, dynamic time) {
      if (base == null) return null;
      if (time == null) return null;

      final raw = time.toString().trim();
      if (raw.isEmpty) return null;

      final clean = raw.split(' ').first;
      final parts = clean.split(':').map(int.tryParse).toList();
      if (parts.isEmpty || parts.first == null) return null;

      final hour = parts[0] ?? 0;
      final minute = parts.length > 1 ? parts[1] ?? 0 : 0;
      final second = parts.length > 2 ? parts[2] ?? 0 : 0;

      return DateTime(
        base.year,
        base.month,
        base.day,
        hour,
        minute,
        second,
      );
    }

    Map<String, dynamic>? timeslot = json['timeslot'] is Map
        ? Map<String, dynamic>.from(json['timeslot'])
        : null;

    final subject = json['subject'] ??
        json['subject_name'] ??
        json['subjectName'] ??
        json['assignment']?['subject']?['name'] ??
        json['assignment']?['subject']?['code'] ??
        '';

    final className = json['class_name'] ??
        json['className'] ??
        json['assignment']?['classUnit']?['name'] ??
        json['assignment']?['classUnit']?['code'] ??
        '';

    final room = json['room'] is Map
        ? (json['room']['name'] ?? json['room']['code'] ?? '')
        : (json['room'] ?? '');

    final base = baseDate();

    DateTime? start = parseDate(json['start_time'] ??
        json['startTime'] ??
        json['start'] ??
        json['session_start']);

    DateTime? end = parseDate(
      json['end_time'] ?? json['endTime'] ?? json['end'],
    );

    if (start == null) {
      final candidate = json['start_time'] ??
          json['start'] ??
          json['startTime'] ??
          timeslot?['start_time'] ??
          timeslot?['startTime'];
      start = combineWithBase(base, candidate);
    }

    if (end == null) {
      final candidate = json['end_time'] ??
          json['end'] ??
          json['endTime'] ??
          timeslot?['end_time'] ??
          timeslot?['endTime'];
      end = combineWithBase(base, candidate);
    }

    start ??= combineWithBase(base, timeslot?['start_time']);
    end ??= combineWithBase(base, timeslot?['end_time']);

    if (end == null && json['duration_minutes'] != null) {
      final minutes = int.tryParse('${json['duration_minutes']}');
      if (minutes != null) {
        end = (start ?? base ?? DateTime.now()).add(Duration(minutes: minutes));
      }
    }

    start ??= base ?? DateTime.now();
    end ??= start.add(const Duration(minutes: 50));

    final status = (json['status'] ?? '').toString().toUpperCase();

    return ScheduleItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      subject: subject.toString(),
      className: className.toString(),
      room: room.toString(),
      startTime: start,
      endTime: end,
      status: status.isEmpty ? 'PLANNED' : status,
      raw: json,
    );
  }

  Color statusColor(ColorScheme cs) {
    switch (status) {
      case 'DONE':
      case 'MAKEUP_DONE':
        return Colors.green;
      case 'TEACHING':
        return cs.primary;
      case 'CANCELED':
        return Colors.redAccent;
      case 'MAKEUP_PLANNED':
        return Colors.orange;
      default:
        return cs.secondary;
    }
  }

  String statusLabel() {
    switch (status) {
      case 'DONE':
        return 'Done';
      case 'MAKEUP_DONE':
        return 'Makeup Done';
      case 'TEACHING':
        return 'Teaching';
      case 'CANCELED':
        return 'Canceled';
      case 'MAKEUP_PLANNED':
        return 'Makeup Planned';
      default:
        return 'Upcoming';
    }
  }
}
