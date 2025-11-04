enum ScheduleStatus { done, teaching, canceled }

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  User({required this.id, required this.name, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        role: (j['role'] ?? 'lecturer').toString(),
      );
}

class ScheduleItem {
  final int id;
  final DateTime date;
  final String subject;
  final String room;
  final String className;
  final String start;
  final String end;
  final ScheduleStatus status;

  ScheduleItem({
    required this.id,
    required this.date,
    required this.subject,
    required this.room,
    required this.className,
    required this.start,
    required this.end,
    required this.status,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> j) {
    final ts = j['timeslot'] ?? {};
    final asg = j['assignment'] ?? {};
    final subj = asg['subject'] ?? {};
    final cu   = asg['classUnit'] ?? {};
    final room = j['room'] ?? {};

    final statusStr = (j['status'] ?? '').toString().toLowerCase();
    final st = (statusStr == 'done' || statusStr == 'completed')
        ? ScheduleStatus.done
        : (statusStr == 'canceled' || statusStr == 'cancelled')
            ? ScheduleStatus.canceled
            : ScheduleStatus.teaching;

    return ScheduleItem(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      date: DateTime.tryParse(j['session_date'] ?? j['date'] ?? '') ?? DateTime.now(),
      subject: (j['subject'] ?? subj['name'] ?? subj['code'] ?? '').toString(),
      room: (j['room'] ?? room['code'] ?? room['name'] ?? '').toString(),
      className: (j['class'] ?? cu['code'] ?? cu['name'] ?? '').toString(),
      start: (j['start_time'] ?? ts['start_time'] ?? '').toString(),
      end: (j['end_time'] ?? ts['end_time'] ?? '').toString(),
      status: st,
    );
  }

  String get timeLabel => '$start - $end';
  bool isSameDate(DateTime d) => d.year == date.year && d.month == date.month && d.day == date.day;
}
