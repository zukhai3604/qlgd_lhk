// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'makeup_api.dart';

class LecturerMakeupHistoryPage extends StatefulWidget {
  const LecturerMakeupHistoryPage({super.key});
  @override
  State<LecturerMakeupHistoryPage> createState() =>
      _LecturerMakeupHistoryPageState();
}

class _LecturerMakeupHistoryPageState
    extends State<LecturerMakeupHistoryPage> {
  final _api = LecturerMakeupApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _allItems =
      const []; // Lưu tất cả items để filter client-side
  String?
      _selectedStatus; // null = tất cả, 'PENDING', 'APPROVED', 'REJECTED', 'CANCELED'

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = await _api.list(); // tất cả đơn dạy bù

      print('MakeupHistory: Received ${list.length} items from API');
      if (list.isNotEmpty) {
        print('MakeupHistory: First item keys: ${list.first.keys.toList()}');
      }

      // Chuẩn hóa dữ liệu và gộp các đơn liền kề
      final normalized = _normalizeItems(list);
      final grouped = _groupConsecutiveMakeupRequests(normalized);

      // Lưu tất cả items để filter client-side
      _allItems = grouped;

      // Filter theo trạng thái nếu có
      _applyFilter();
      _error = null;
    } catch (e, stackTrace) {
      print('MakeupHistory: Error fetching data: $e');
      print('MakeupHistory: StackTrace: $stackTrace');
      _error = 'Không tải được lịch sử dạy bù: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Chuẩn hóa dữ liệu để dễ so sánh và gộp
  List<Map<String, dynamic>> _normalizeItems(
      List<Map<String, dynamic>> items) {
    return items.map((it) {
      // Extract subject name với nhiều fallback (xử lý null, empty string, và 'Môn học')
      String subject = '';

      // Thử từ subject (có thể là string hoặc Map)
      if (it['subject'] != null) {
        if (it['subject'] is Map) {
          subject = (it['subject'] as Map)['name']?.toString()?.trim() ?? '';
        } else {
          final subjStr = it['subject'].toString().trim();
          if (subjStr.isNotEmpty &&
              subjStr != 'Môn học' &&
              subjStr != 'null') {
            subject = subjStr;
          }
        }
      }

      // Nếu vẫn rỗng hoặc là placeholder, thử từ subject_name
      if (subject.isEmpty || subject == 'Môn học' || subject == 'null') {
        final subjName = it['subject_name']?.toString()?.trim() ?? '';
        if (subjName.isNotEmpty &&
            subjName != 'Môn học' &&
            subjName != 'null') {
          subject = subjName;
        }
      }

      // Nếu vẫn rỗng, thử từ leave.schedule.assignment.subject (nested)
      if (subject.isEmpty || subject == 'Môn học' || subject == 'null') {
        try {
          final leave = it['leave'];
          if (leave is Map) {
            final schedule = leave['schedule'];
            if (schedule is Map) {
              final assignment = schedule['assignment'];
              if (assignment is Map) {
                final subjectObj = assignment['subject'];
                if (subjectObj is Map) {
                  final subjName =
                      subjectObj['name']?.toString()?.trim() ?? '';
                  if (subjName.isNotEmpty &&
                      subjName != 'Môn học' &&
                      subjName != 'null') {
                    subject = subjName;
                  }
                }
              }
            }
          }
        } catch (_) {
          // Ignore errors
        }
      }

      // Nếu vẫn rỗng, dùng placeholder
      if (subject.isEmpty || subject == 'null') {
        subject = 'Môn học';
      }

      // Extract class name với nhiều fallback (xử lý null và empty)
      String className = '';

      // Thử từ class_name hoặc class_code
      final classNm = it['class_name']?.toString()?.trim() ?? '';
      final classCd = it['class_code']?.toString()?.trim() ?? '';
      className = classNm.isNotEmpty ? classNm : (classCd.isNotEmpty ? classCd : '');

      // Thử từ class (có thể là Map)
      if (className.isEmpty && it['class'] is Map) {
        className =
            (it['class'] as Map)['name']?.toString()?.trim() ?? '';
      }

      // Nếu vẫn rỗng, thử từ leave.schedule.assignment.classUnit (nested)
      if (className.isEmpty) {
        try {
          final leave = it['leave'];
          if (leave is Map) {
            final schedule = leave['schedule'];
            if (schedule is Map) {
              final assignment = schedule['assignment'];
              if (assignment is Map) {
                final classUnit = assignment['classUnit'];
                if (classUnit is Map) {
                  className =
                      classUnit['name']?.toString()?.trim() ?? '';
                }
              }
            }
          }
        } catch (_) {
          // Ignore errors
        }
      }

      // Nếu vẫn rỗng, để trống (không dùng placeholder)
      className = className == 'null' ? '' : className;

      // Extract date (suggested_date hoặc makeup_date)
      final dateStr =
          it['suggested_date'] ?? it['makeup_date'] ?? it['date'];
      final date =
          dateStr?.toString().split(' ').first ?? ''; // YYYY-MM-DD

      // Extract time from timeslot (xử lý null và empty)
      String startTime = '';
      String endTime = '';

      // Ưu tiên từ timeslot object
      if (it['timeslot'] is Map) {
        final ts = it['timeslot'] as Map;
        startTime = ts['start_time']?.toString()?.trim() ?? '';
        endTime = ts['end_time']?.toString()?.trim() ?? '';
      }

      // Fallback to direct fields
      if (startTime.isEmpty || startTime == 'null') {
        startTime = it['start_time']?.toString()?.trim() ?? '';
      }
      if (endTime.isEmpty || endTime == 'null') {
        endTime = it['end_time']?.toString()?.trim() ?? '';
      }

      // Xử lý null strings
      startTime = startTime == 'null' ? '' : startTime;
      endTime = endTime == 'null' ? '' : endTime;

      // Extract room (xử lý null và empty)
      String room = '';

      // Ưu tiên từ room object
      if (it['room'] is Map) {
        final r = it['room'] as Map;
        room = r['name']?.toString()?.trim() ??
            r['code']?.toString()?.trim() ??
            '';
      }

      // Fallback to room_name hoặc room (string)
      if (room.isEmpty || room == 'null') {
        room = it['room_name']?.toString()?.trim() ?? '';
      }
      if (room.isEmpty || room == 'null') {
        final roomStr = it['room']?.toString()?.trim() ?? '';
        if (roomStr.isNotEmpty && roomStr != 'null') {
          room = roomStr;
        }
      }

      // Xử lý null strings
      room = room == 'null' ? '' : room;

      final status = (it['status'] ?? 'PENDING').toString();

      return {
        ...it,
        '_normalized_subject': subject,
        '_normalized_class_name': className,
        '_normalized_date': date,
        '_normalized_start_time': startTime,
        '_normalized_end_time': endTime,
        '_normalized_room': room,
        '_normalized_status': status,
      };
    }).toList();
  }

  /// Gộp các đơn đăng ký dạy bù liền kề nhau của cùng môn học thành 1 đơn
  List<Map<String, dynamic>> _groupConsecutiveMakeupRequests(
      List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return [];

    // Sắp xếp theo ngày và thời gian bắt đầu
    final sorted = List<Map<String, dynamic>>.from(requests);
    sorted.sort((a, b) {
      final dateA = (a['_normalized_date'] ?? '').toString();
      final dateB = (b['_normalized_date'] ?? '').toString();
      if (dateA != dateB) return dateA.compareTo(dateB);

      final startA = (a['_normalized_start_time'] ?? '--:--').toString();
      final startB = (b['_normalized_start_time'] ?? '--:--').toString();
      if (startA == '--:--' && startB == '--:--') return 0;
      if (startA == '--:--') return 1;
      if (startB == '--:--') return -1;
      return startA.compareTo(startB);
    });

    final result = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < sorted.length; i++) {
      if (processed.contains(i)) continue;

      final current = sorted[i];
      final subject = (current['_normalized_subject'] ?? '').toString();
      final className =
          (current['_normalized_class_name'] ?? '').toString();
      final room = (current['_normalized_room'] ?? '').toString();
      final date = (current['_normalized_date'] ?? '').toString();
      final status = (current['_normalized_status'] ?? '').toString();

      // Tìm các đơn liền kề có cùng subject, class, ngày, status (không yêu cầu cùng phòng)
      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSubject =
            (next['_normalized_subject'] ?? '').toString();
        final nextClassName =
            (next['_normalized_class_name'] ?? '').toString();
        final nextDate = (next['_normalized_date'] ?? '').toString();
        final nextStatus =
            (next['_normalized_status'] ?? '').toString();

        // Kiểm tra cùng môn, lớp, ngày, status (không bắt buộc cùng phòng)
        if (subject != nextSubject ||
            className != nextClassName ||
            date != nextDate ||
            status != nextStatus) {
          break;
        }

        // Nới lỏng: Nếu cùng ngày, cùng môn, cùng lớp, cùng status thì gộp luôn
        group.add(next);
        groupIndices.add(j);
      }

      // Đánh dấu đã xử lý
      for (final idx in groupIndices) {
        processed.add(idx);
      }

      // Nếu chỉ có 1 đơn, giữ nguyên
      if (group.length == 1) {
        result.add(current);
      } else {
        // Gộp thành 1 đơn: lấy start_time từ đơn đầu, end_time từ đơn cuối
        final first = group.first;
        final last = group.last;

        final merged = Map<String, dynamic>.from(first);

        // Lấy start_time từ đơn đầu (thời gian dạy bù)
        final startTime =
            (first['_normalized_start_time'] ?? '--:--').toString();

        // Lấy end_time từ đơn cuối (thời gian dạy bù)
        final endTime =
            (last['_normalized_end_time'] ?? '--:--').toString();

        // Cập nhật timeslot với thời gian mới
        if (merged['timeslot'] is Map) {
          final ts = Map<String, dynamic>.from(
              merged['timeslot'] as Map);
          if (startTime.isNotEmpty && startTime != '--:--') {
            ts['start_time'] = startTime.split(':').length == 2
                ? '$startTime:00'
                : startTime;
          }
          if (endTime.isNotEmpty && endTime != '--:--') {
            ts['end_time'] = endTime.split(':').length == 2
                ? '$endTime:00'
                : endTime;
          }
          merged['timeslot'] = ts;
        } else {
          merged['timeslot'] = {
            'start_time': startTime.isNotEmpty && startTime != '--:--'
                ? (startTime.split(':').length == 2
                    ? '$startTime:00'
                    : startTime)
                : null,
            'end_time': endTime.isNotEmpty && endTime != '--:--'
                ? (endTime.split(':').length == 2
                    ? '$endTime:00'
                    : endTime)
                : null,
          };
        }

        // Cập nhật start_time và end_time trực tiếp
        merged['start_time'] = startTime;
        merged['end_time'] = endTime;
        merged['_normalized_start_time'] = startTime;
        merged['_normalized_end_time'] = endTime;

        // Merge phòng
        String mergedRoom =
            (first['_normalized_room'] ?? '').toString();
        if (mergedRoom.isEmpty) {
          for (final req in group) {
            final r = (req['_normalized_room'] ?? '').toString();
            if (r.isNotEmpty) {
              mergedRoom = r;
              break;
            }
          }
          // Nếu vẫn rỗng, thử extract từ room object
          if (mergedRoom.isEmpty && merged['room'] is Map) {
            final r = merged['room'] as Map;
            mergedRoom = r['name']?.toString() ??
                r['code']?.toString() ??
                '';
          }
        }
        merged['_normalized_room'] = mergedRoom;
        if (mergedRoom.isNotEmpty) {
          if (merged['room'] is Map) {
            final r = Map<String, dynamic>.from(
                merged['room'] as Map);
            r['name'] = mergedRoom;
            r['code'] = mergedRoom;
            merged['room'] = r;
          } else {
            merged['room'] = {
              'name': mergedRoom,
              'code': mergedRoom,
            };
          }
          merged['room_name'] = mergedRoom;
        }

        // Lưu thông tin buổi học gốc: lấy từ đơn đầu
        Object? originalDate = first['original_date'];
        if (originalDate == null && first['leave'] is Map) {
          final leave = first['leave'] as Map;
          originalDate = leave['original_date'];
        }
        merged['original_date'] = originalDate;

        // ========= Thu thập thời gian học gốc từ TẤT CẢ leave request trong group =========
        String? firstOriginalStart;
        String? lastOriginalEnd;

        final allStartTimes = <String>[];
        final allEndTimes = <String>[];

        final processedLeaveIds = <int>{};
        final processedScheduleIds = <int>{};

        for (final req in group) {
          final leaveRequestId = req['leave_request_id'];
          if (leaveRequestId != null) {
            final lrId = int.tryParse('$leaveRequestId');
            if (lrId != null && processedLeaveIds.contains(lrId)) {
              continue;
            }
            if (lrId != null) {
              processedLeaveIds.add(lrId);
            }
          }

          String? reqStartTime;
          String? reqEndTime;

          if (req['leave'] is Map) {
            final leave = req['leave'] as Map;
            final scheduleId = leave['schedule_id'];
            if (scheduleId != null) {
              final sId = int.tryParse('$scheduleId');
              if (sId != null &&
                  processedScheduleIds.contains(sId)) {
                continue;
              }
              if (sId != null) {
                processedScheduleIds.add(sId);
              }
            }

            if (leave['schedule'] is Map) {
              final schedule = leave['schedule'] as Map;
              if (schedule['timeslot'] is Map) {
                final timeslot = schedule['timeslot'] as Map;
                reqStartTime =
                    timeslot['start_time']?.toString()?.trim();
                reqEndTime =
                    timeslot['end_time']?.toString()?.trim();
              }
            }
            // Fallback về original_time
            if (reqStartTime == null ||
                reqStartTime.isEmpty ||
                reqEndTime == null ||
                reqEndTime.isEmpty) {
              if (leave['original_time'] is Map) {
                final origTime = leave['original_time'] as Map;
                if (reqStartTime == null ||
                    reqStartTime.isEmpty) {
                  reqStartTime =
                      origTime['start_time']?.toString()?.trim();
                }
                if (reqEndTime == null || reqEndTime.isEmpty) {
                  reqEndTime =
                      origTime['end_time']?.toString()?.trim();
                }
              }
            }
          }

          // Fallback về original_start_time & original_end_time trực tiếp
          if (reqStartTime == null || reqStartTime.isEmpty) {
            reqStartTime =
                req['original_start_time']?.toString()?.trim();
          }
          if (reqEndTime == null || reqEndTime.isEmpty) {
            reqEndTime =
                req['original_end_time']?.toString()?.trim();
          }

          print('DEBUG Grouping: Processing req #${req['id']}');
          print('  - leave_request_id: ${req['leave_request_id']}');
          if (req['leave'] is Map) {
            print(
                '  - schedule_id: ${(req['leave'] as Map)['schedule_id']}');
          }
          print('  - reqStartTime: $reqStartTime');
          print('  - reqEndTime: $reqEndTime');

          if (reqStartTime != null &&
              reqStartTime.isNotEmpty &&
              !allStartTimes.contains(reqStartTime)) {
            allStartTimes.add(reqStartTime);
          }
          if (reqEndTime != null &&
              reqEndTime.isNotEmpty &&
              !allEndTimes.contains(reqEndTime)) {
            allEndTimes.add(reqEndTime);
          }
        }

        if (allStartTimes.isNotEmpty) {
          final timesWithMinutes =
              allStartTimes.map<Map<String, dynamic>>((t) {
            final minutes = _parseTimeToMinutes(t);
            return {
              'time': t,
              'minutes': minutes ?? 0,
            };
          }).toList();
          timesWithMinutes.sort((a, b) =>
              (a['minutes'] as int).compareTo(b['minutes'] as int));
          firstOriginalStart =
              timesWithMinutes.first['time'] as String;
        }

        if (allEndTimes.isNotEmpty) {
          final timesWithMinutes =
              allEndTimes.map<Map<String, dynamic>>((t) {
            final minutes = _parseTimeToMinutes(t);
            return {
              'time': t,
              'minutes': minutes ?? 0,
            };
          }).toList();
          timesWithMinutes.sort((a, b) =>
              (a['minutes'] as int).compareTo(b['minutes'] as int));
          lastOriginalEnd =
              timesWithMinutes.last['time'] as String;
        }

        print('DEBUG Grouping Original Time (ALL LEAVE REQUESTS):');
        print('  - Group size: ${group.length}');
        print('  - All start times: $allStartTimes');
        print('  - All end times: $allEndTimes');
        print('  - firstOriginalStart: $firstOriginalStart');
        print('  - lastOriginalEnd: $lastOriginalEnd');

        if (firstOriginalStart != null &&
            firstOriginalStart.isNotEmpty) {
          merged['original_start_time'] = firstOriginalStart;
        }
        if (lastOriginalEnd != null && lastOriginalEnd.isNotEmpty) {
          merged['original_end_time'] = lastOriginalEnd;
        }

        // Lưu lý do nghỉ
        merged['leave_reason'] = first['leave_reason'] ??
            first['leave']?['reason'] ??
            '';

        // Lưu danh sách các makeup_request_ids
        final makeupRequestIds = group
            .map((r) {
              final id = r['id'];
              return id != null ? int.tryParse('$id') : null;
            })
            .whereType<int>()
            .toList();
        merged['_grouped_makeup_request_ids'] = makeupRequestIds;

        result.add(merged);
      }
    }

    return result;
  }

  /// Parse thời gian HH:mm thành số phút (ví dụ: "15:40" -> 940)
  int? _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--') return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _hhmm(String? t) {
    if (t == null || t.isEmpty) return '--:--';
    final parts = t.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return t;
  }

  String _ddmmyyyy(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final raw = iso.length >= 10 ? iso.substring(0, 10) : iso;
    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateTime.parse(raw));
    } catch (_) {
      return iso;
    }
  }

  ({String label, Color color}) _st(String s) {
    switch ((s).toUpperCase()) {
      case 'APPROVED':
        return (label: 'Đã duyệt', color: Colors.green);
      case 'REJECTED':
        return (label: 'Từ chối', color: Colors.red);
      case 'PENDING':
        return (label: 'Chờ duyệt', color: Colors.orange);
      case 'CANCELED':
        return (label: 'Đã hủy', color: Colors.grey);
      default:
        return (label: s, color: Colors.blueGrey);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[800]),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(
    Map<String, dynamic> item,
    String subject,
    String className,
    String date,
    String tr,
    String room,
    String originalDate,
    String originalTr,
    String leaveReason,
    ({String label, Color color}) status,
    bool isGrouped,
    int groupCount,
  ) {
    // Debug: Log dữ liệu khi mở dialog
    print('=== MAKEUP DETAIL DIALOG ===');
    print('Item keys: ${item.keys.toList()}');
    print('Subject (param): $subject');
    print('ClassName (param): $className');
    print('Date (param): $date');
    print('Time (param): $tr');
    print('Room (param): $room');
    print('Item subject: ${item['subject']}');
    print('Item subject_name: ${item['subject_name']}');
    print('Item class_name: ${item['class_name']}');
    print('Item timeslot: ${item['timeslot']}');
    print('Item room: ${item['room']}');
    print('Item leave: ${item['leave']}');
    print(
        'Item _normalized_subject: ${item['_normalized_subject']}');
    print(
        'Item _normalized_class_name: ${item['_normalized_class_name']}');
    print('===========================');

    // Extract lại từ item
    String finalSubject = '';
    if (subject.isNotEmpty &&
        subject != 'Môn học' &&
        subject != 'null') {
      finalSubject = subject.trim();
    } else {
      finalSubject =
          item['_normalized_subject']?.toString()?.trim() ?? '';
      if (finalSubject.isEmpty ||
          finalSubject == 'Môn học' ||
          finalSubject == 'null') {
        if (item['subject'] != null) {
          if (item['subject'] is Map) {
            finalSubject = (item['subject'] as Map)['name']
                    ?.toString()
                    ?.trim() ??
                '';
          } else {
            final subjStr = item['subject'].toString().trim();
            if (subjStr.isNotEmpty &&
                subjStr != 'Môn học' &&
                subjStr != 'null') {
              finalSubject = subjStr;
            }
          }
        }
        if (finalSubject.isEmpty ||
            finalSubject == 'Môn học' ||
            finalSubject == 'null') {
          finalSubject =
              item['subject_name']?.toString()?.trim() ?? '';
        }
        // Thử từ nested
        if (finalSubject.isEmpty ||
            finalSubject == 'Môn học' ||
            finalSubject == 'null') {
          try {
            final leave = item['leave'];
            if (leave is Map) {
              final schedule = leave['schedule'];
              if (schedule is Map) {
                final assignment = schedule['assignment'];
                if (assignment is Map) {
                  final subjectObj = assignment['subject'];
                  if (subjectObj is Map) {
                    finalSubject =
                        subjectObj['name']?.toString()?.trim() ??
                            '';
                  }
                }
              }
            }
          } catch (_) {}
        }
      }
    }
    if (finalSubject.isEmpty || finalSubject == 'null') {
      finalSubject = 'Môn học';
    }

    String finalClassName = '';
    if (className.isNotEmpty && className != 'null') {
      finalClassName = className.trim();
    } else {
      finalClassName =
          item['_normalized_class_name']?.toString()?.trim() ??
              '';
      if (finalClassName.isEmpty ||
          finalClassName == 'null') {
        final classNm =
            item['class_name']?.toString()?.trim() ?? '';
        final classCd =
            item['class_code']?.toString()?.trim() ?? '';
        finalClassName = classNm.isNotEmpty
            ? classNm
            : (classCd.isNotEmpty ? classCd : '');
        if (finalClassName.isEmpty && item['class'] is Map) {
          finalClassName =
              (item['class'] as Map)['name']?.toString()?.trim() ??
                  '';
        }
        // Thử từ nested
        if (finalClassName.isEmpty) {
          try {
            final leave = item['leave'];
            if (leave is Map) {
              final schedule = leave['schedule'];
              if (schedule is Map) {
                final assignment = schedule['assignment'];
                if (assignment is Map) {
                  final classUnit = assignment['classUnit'];
                  if (classUnit is Map) {
                    finalClassName =
                        classUnit['name']?.toString()?.trim() ??
                            '';
                  }
                }
              }
            }
          } catch (_) {}
        }
      }
    }
    finalClassName = finalClassName == 'null' ? '' : finalClassName;

    final finalDate = date.isNotEmpty
        ? date
        : _ddmmyyyy(item['suggested_date'] ??
            item['makeup_date'] ??
            item['date']?.toString());

    // Extract thời gian với nhiều fallback
    String finalStartTime = '';
    String finalEndTime = '';
    if (tr.isNotEmpty && tr.contains(' - ')) {
      final parts = tr.split(' - ');
      if (parts.length == 2) {
        finalStartTime = parts[0].trim();
        finalEndTime = parts[1].trim();
      }
    } else {
      finalStartTime =
          item['_normalized_start_time']?.toString() ?? '';
      finalEndTime =
          item['_normalized_end_time']?.toString() ?? '';
      if (finalStartTime.isEmpty || finalEndTime.isEmpty) {
        if (item['timeslot'] is Map) {
          final ts = item['timeslot'] as Map;
          finalStartTime =
              ts['start_time']?.toString() ?? finalStartTime;
          finalEndTime =
              ts['end_time']?.toString() ?? finalEndTime;
        }
        if (finalStartTime.isEmpty) {
          finalStartTime =
              item['start_time']?.toString() ?? '';
        }
        if (finalEndTime.isEmpty) {
          finalEndTime = item['end_time']?.toString() ?? '';
        }
      }
    }
    finalStartTime =
        finalStartTime == 'null' ? '' : finalStartTime;
    finalEndTime = finalEndTime == 'null' ? '' : finalEndTime;

    final finalTr =
        finalStartTime.isNotEmpty &&
                finalEndTime.isNotEmpty &&
                finalStartTime != '--:--' &&
                finalEndTime != '--:--'
            ? '${_hhmm(finalStartTime)} - ${_hhmm(finalEndTime)}'
            : '';

    String finalRoom = '';
    if (room.isNotEmpty && room != 'null') {
      finalRoom = room.trim();
    } else {
      finalRoom = item['_normalized_room']?.toString()?.trim() ??
          '';
      if (finalRoom.isEmpty || finalRoom == 'null') {
        if (item['room'] is Map) {
          final r = item['room'] as Map;
          finalRoom =
              r['name']?.toString()?.trim() ??
                  r['code']?.toString()?.trim() ??
                  '';
        }
        if (finalRoom.isEmpty || finalRoom == 'null') {
          finalRoom =
              item['room_name']?.toString()?.trim() ?? '';
        }
        if (finalRoom.isEmpty || finalRoom == 'null') {
          final roomStr =
              item['room']?.toString()?.trim() ?? '';
          if (roomStr.isNotEmpty && roomStr != 'null') {
            finalRoom = roomStr;
          }
        }
      }
    }
    finalRoom = finalRoom == 'null' ? '' : finalRoom;

    final finalOriginalDate = originalDate.isNotEmpty
        ? originalDate
        : (() {
            if (item['original_date'] != null) {
              return _ddmmyyyy(
                  item['original_date']?.toString());
            }
            if (item['leave'] is Map) {
              final leave = item['leave'] as Map;
              if (leave['original_date'] != null) {
                return _ddmmyyyy(
                    leave['original_date']?.toString());
              }
            }
            return '';
          })();

    String finalOriginalStartTime = '';
    String finalOriginalEndTime = '';

    final groupedIds = item['_grouped_makeup_request_ids'];
    if (groupedIds is List && groupedIds.length > 1) {
      finalOriginalStartTime =
          item['original_start_time']?.toString() ?? '';
      finalOriginalEndTime =
          item['original_end_time']?.toString() ?? '';

      if (finalOriginalStartTime.isEmpty ||
          finalOriginalEndTime.isEmpty) {
        if (originalTr.isNotEmpty && originalTr.contains(' - ')) {
          final parts = originalTr.split(' - ');
          if (parts.length == 2) {
            finalOriginalStartTime = parts[0].trim();
            finalOriginalEndTime = parts[1].trim();
          }
        }
      }
    } else {
      finalOriginalStartTime =
          item['original_start_time']?.toString() ?? '';
      finalOriginalEndTime =
          item['original_end_time']?.toString() ?? '';

      if (finalOriginalStartTime.isEmpty ||
          finalOriginalEndTime.isEmpty) {
        if (originalTr.isNotEmpty && originalTr.contains(' - ')) {
          final parts = originalTr.split(' - ');
          if (parts.length == 2) {
            finalOriginalStartTime = parts[0].trim();
            finalOriginalEndTime = parts[1].trim();
          }
        }
      }
    }

    // Fallback: lấy từ leave request hiện tại
    if (finalOriginalStartTime.isEmpty ||
        finalOriginalEndTime.isEmpty) {
      if (item['leave'] is Map) {
        final leave = item['leave'] as Map;
        if (leave['schedule'] is Map) {
          final schedule = leave['schedule'] as Map;
          if (schedule['timeslot'] is Map) {
            final timeslot = schedule['timeslot'] as Map;
            if (finalOriginalStartTime.isEmpty) {
              finalOriginalStartTime =
                  timeslot['start_time']?.toString() ?? '';
            }
            if (finalOriginalEndTime.isEmpty) {
              finalOriginalEndTime =
                  timeslot['end_time']?.toString() ?? '';
            }
          }
        }
        if (finalOriginalStartTime.isEmpty ||
            finalOriginalEndTime.isEmpty) {
          if (leave['original_time'] is Map) {
            final origTime = leave['original_time'] as Map;
            if (finalOriginalStartTime.isEmpty) {
              finalOriginalStartTime =
                  origTime['start_time']?.toString() ?? '';
            }
            if (finalOriginalEndTime.isEmpty) {
              finalOriginalEndTime =
                  origTime['end_time']?.toString() ?? '';
            }
          }
        }
      }
    }

    print('DEBUG Original Time Extraction:');
    print(
        '  - item[original_start_time]: ${item['original_start_time']}');
    print(
        '  - item[original_end_time]: ${item['original_end_time']}');
    print('  - originalTr param: $originalTr');
    print('  - groupedIds: $groupedIds');
    print(
        '  - Final: $finalOriginalStartTime - $finalOriginalEndTime');

    final finalOriginalTr =
        finalOriginalStartTime.isNotEmpty &&
                finalOriginalEndTime.isNotEmpty
            ? '${_hhmm(finalOriginalStartTime)} - ${_hhmm(finalOriginalEndTime)}'
            : '';

    final finalLeaveReason = leaveReason.isNotEmpty
        ? leaveReason
        : (item['leave_reason']?.toString() ??
            (item['leave'] is Map
                ? (item['leave'] as Map)['reason']
                    ?.toString()
                : null) ??
            '');

    // Extract thông tin buổi học gốc
    String origSubject = '';
    String origClass = '';
    String origTsCode = '';
    String origRoomName = '';

    if (item['leave'] is Map) {
      final leave = item['leave'] as Map;
      if (leave['schedule'] is Map) {
        final schedule = leave['schedule'] as Map;
        if (schedule['assignment'] is Map) {
          final assignment = schedule['assignment'] as Map;
          if (assignment['subject'] is Map) {
            origSubject = (assignment['subject'] as Map)['name']
                    ?.toString() ??
                '';
          }
          if (assignment['classUnit'] is Map) {
            origClass =
                (assignment['classUnit'] as Map)['name']
                        ?.toString() ??
                    '';
          }
        }
        if (schedule['timeslot'] is Map) {
          origTsCode =
              (schedule['timeslot'] as Map)['code']?.toString() ??
                  '';
        }
        if (schedule['room'] is Map) {
          final origRoom = schedule['room'] as Map;
          origRoomName =
              origRoom['name']?.toString() ??
                  origRoom['code']?.toString() ??
                  '';
        }
      }
    }

    // Extract timeslot code của buổi dạy bù
    String makeupTsCode = '';
    if (item['timeslot'] is Map) {
      makeupTsCode =
          (item['timeslot'] as Map)['code']?.toString() ?? '';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chi tiết đăng ký dạy bù'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trạng thái
              Row(
                children: [
                  const Text(
                    'Trạng thái: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Chip(
                    label: Text(status.label),
                    backgroundColor:
                        status.color.withOpacity(0.15),
                    side: BorderSide(color: status.color),
                    labelStyle: TextStyle(
                      color: status.color,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thông tin buổi dạy bù
              const Text(
                'Thông tin buổi dạy bù:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Môn: ${finalSubject.isNotEmpty && finalSubject != 'Môn học' ? finalSubject : 'Chưa có thông tin'}',
                ),
              ),
              if (finalClassName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• Lớp: $finalClassName'),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• Lớp: Chưa có thông tin',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Ngày: ${finalDate.isNotEmpty ? finalDate : 'Chưa có thông tin'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Giờ: ${finalTr.isNotEmpty ? finalTr : 'Chưa có thông tin'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Phòng: ${finalRoom.isNotEmpty ? finalRoom : 'Chưa có thông tin'}',
                ),
              ),

              // Thông tin buổi học gốc (đã nghỉ)
              const SizedBox(height: 16),
              const Text(
                'Thông tin buổi học gốc (đã nghỉ):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Môn: ${origSubject.isNotEmpty && origSubject != 'Môn học' ? origSubject : 'Chưa có thông tin'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Lớp: ${origClass.isNotEmpty ? origClass : 'Chưa có thông tin'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Ngày: ${finalOriginalDate.isNotEmpty ? finalOriginalDate : 'Chưa có thông tin'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Giờ: ${finalOriginalTr.isNotEmpty ? finalOriginalTr : 'Chưa có thông tin'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Phòng: ${origRoomName.isNotEmpty ? origRoomName : 'Chưa có thông tin'}',
                ),
              ),

              // Lý do nghỉ
              const SizedBox(height: 16),
              const Text(
                'Lý do nghỉ:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                finalLeaveReason.isNotEmpty
                    ? finalLeaveReason
                    : 'Chưa có thông tin',
                style: TextStyle(
                  fontStyle: finalLeaveReason.isNotEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: finalLeaveReason.isEmpty
                      ? Colors.grey[600]
                      : null,
                ),
              ),

              // Ghi chú (nếu có)
              if (item['note'] != null &&
                  item['note'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Ghi chú:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  item['note'].toString(),
                  style:
                      const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],

              // Thông báo theo trạng thái
              const SizedBox(height: 16),
              if (status.label == 'Đã duyệt') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn đăng ký dạy bù đã được duyệt.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (status.label == 'Chờ duyệt') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn đăng ký dạy bù đang chờ được duyệt.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (status.label == 'Từ chối') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn đăng ký dạy bù đã bị từ chối.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đăng ký dạy bù')),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chờ duyệt', 'PENDING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã duyệt', 'APPROVED'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Từ chối', 'REJECTED'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã hủy', 'CANCELED'),
                ],
              ),
            ),
          ),
          // List content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('Chưa có đơn dạy bù.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 12, 16, 16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final it = _items[i];

                        // Subject
                        String subject = it['_normalized_subject']
                                ?.toString()
                                ?.trim() ??
                            '';
                        if (subject.isEmpty ||
                            subject == 'Môn học' ||
                            subject == 'null') {
                          if (it['subject'] != null) {
                            if (it['subject'] is Map) {
                              subject =
                                  (it['subject'] as Map)['name']
                                          ?.toString()
                                          ?.trim() ??
                                      '';
                            } else {
                              final subjStr =
                                  it['subject'].toString().trim();
                              if (subjStr.isNotEmpty &&
                                  subjStr != 'Môn học' &&
                                  subjStr != 'null') {
                                subject = subjStr;
                              }
                            }
                          }
                          if (subject.isEmpty ||
                              subject == 'Môn học' ||
                              subject == 'null') {
                            subject = it['subject_name']
                                    ?.toString()
                                    ?.trim() ??
                                '';
                          }
                          // nested
                          if (subject.isEmpty ||
                              subject == 'Môn học' ||
                              subject == 'null') {
                            try {
                              final leave = it['leave'];
                              if (leave is Map) {
                                final schedule =
                                    leave['schedule'];
                                if (schedule is Map) {
                                  final assignment =
                                      schedule['assignment'];
                                  if (assignment is Map) {
                                    final subjectObj =
                                        assignment['subject'];
                                    if (subjectObj is Map) {
                                      subject = subjectObj['name']
                                              ?.toString()
                                              ?.trim() ??
                                          '';
                                    }
                                  }
                                }
                              }
                            } catch (_) {}
                          }
                        }
                        if (subject.isEmpty || subject == 'null') {
                          subject = 'Môn học';
                        }

                        // Class
                        String className =
                            it['_normalized_class_name']
                                    ?.toString()
                                    ?.trim() ??
                                '';
                        if (className.isEmpty ||
                            className == 'null') {
                          final classNm = it['class_name']
                                  ?.toString()
                                  ?.trim() ??
                              '';
                          final classCd = it['class_code']
                                  ?.toString()
                                  ?.trim() ??
                              '';
                          className = classNm.isNotEmpty
                              ? classNm
                              : (classCd.isNotEmpty
                                  ? classCd
                                  : '');
                          if (className.isEmpty &&
                              it['class'] is Map) {
                            className =
                                (it['class'] as Map)['name']
                                        ?.toString()
                                        ?.trim() ??
                                    '';
                          }
                          if (className.isEmpty) {
                            try {
                              final leave = it['leave'];
                              if (leave is Map) {
                                final schedule =
                                    leave['schedule'];
                                if (schedule is Map) {
                                  final assignment =
                                      schedule['assignment'];
                                  if (assignment is Map) {
                                    final classUnit =
                                        assignment['classUnit'];
                                    if (classUnit is Map) {
                                      className = classUnit['name']
                                              ?.toString()
                                              ?.trim() ??
                                          '';
                                    }
                                  }
                                }
                              }
                            } catch (_) {}
                          }
                        }
                        className =
                            className == 'null' ? '' : className;

                        // Date
                        final dateStr = it['suggested_date'] ??
                            it['makeup_date'] ??
                            it['date'];
                        final date =
                            _ddmmyyyy(dateStr?.toString());

                        // Time
                        String startTime = it[
                                    '_normalized_start_time']
                                ?.toString()
                                ?.trim() ??
                            '';
                        String endTime =
                            it['_normalized_end_time']
                                    ?.toString()
                                    ?.trim() ??
                                '';

                        if (startTime.isEmpty ||
                                startTime == '--:--' ||
                                startTime == 'null' ||
                            endTime.isEmpty ||
                                endTime == '--:--' ||
                                endTime == 'null') {
                          if (it['timeslot'] is Map) {
                            final ts = it['timeslot'] as Map;
                            if (startTime.isEmpty ||
                                startTime == '--:--' ||
                                startTime == 'null') {
                              startTime = ts['start_time']
                                      ?.toString()
                                      ?.trim() ??
                                  '';
                            }
                            if (endTime.isEmpty ||
                                endTime == '--:--' ||
                                endTime == 'null') {
                              endTime = ts['end_time']
                                      ?.toString()
                                      ?.trim() ??
                                  '';
                            }
                          }
                          if (startTime.isEmpty ||
                              startTime == '--:--' ||
                              startTime == 'null') {
                            startTime = it['start_time']
                                    ?.toString()
                                    ?.trim() ??
                                '';
                          }
                          if (endTime.isEmpty ||
                              endTime == '--:--' ||
                              endTime == 'null') {
                            endTime = it['end_time']
                                    ?.toString()
                                    ?.trim() ??
                                '';
                          }
                        }
                        startTime =
                            startTime == 'null' ? '' : startTime;
                        endTime = endTime == 'null' ? '' : endTime;

                        final tr =
                            startTime.isNotEmpty &&
                                    endTime.isNotEmpty &&
                                    startTime != '--:--' &&
                                    endTime != '--:--'
                                ? '${_hhmm(startTime)} - ${_hhmm(endTime)}'
                                : '';

                        // Original time
                        String originalStartTime =
                            it['original_start_time']
                                    ?.toString()
                                    ?.trim() ??
                                '';
                        String originalEndTime =
                            it['original_end_time']
                                    ?.toString()
                                    ?.trim() ??
                                '';

                        if (originalStartTime.isEmpty ||
                            originalEndTime.isEmpty) {
                          if (it['leave'] is Map) {
                            final leave = it['leave'] as Map;
                            if (leave['schedule'] is Map) {
                              final schedule =
                                  leave['schedule'] as Map;
                              if (schedule['timeslot'] is Map) {
                                final timeslot =
                                    schedule['timeslot']
                                        as Map;
                                if (originalStartTime.isEmpty) {
                                  originalStartTime =
                                      timeslot['start_time']
                                              ?.toString()
                                              ?.trim() ??
                                          '';
                                }
                                if (originalEndTime.isEmpty) {
                                  originalEndTime =
                                      timeslot['end_time']
                                              ?.toString()
                                              ?.trim() ??
                                          '';
                                }
                              }
                            }
                            if (originalStartTime.isEmpty ||
                                originalEndTime.isEmpty) {
                              if (leave['original_time']
                                  is Map) {
                                final origTime =
                                    leave['original_time']
                                        as Map;
                                if (originalStartTime.isEmpty) {
                                  originalStartTime =
                                      origTime['start_time']
                                              ?.toString()
                                              ?.trim() ??
                                          '';
                                }
                                if (originalEndTime.isEmpty) {
                                  originalEndTime =
                                      origTime['end_time']
                                              ?.toString()
                                              ?.trim() ??
                                          '';
                                }
                              }
                            }
                          }
                        }

                        final originalTr =
                            originalStartTime.isNotEmpty &&
                                    originalEndTime.isNotEmpty
                                ? '${_hhmm(originalStartTime)} - ${_hhmm(originalEndTime)}'
                                : '';

                        // Original date
                        String originalDate = '';
                        if (it['original_date'] != null) {
                          originalDate = _ddmmyyyy(
                              it['original_date']?.toString());
                        } else if (it['leave'] is Map) {
                          final leave = it['leave'] as Map;
                          if (leave['original_date'] != null) {
                            originalDate = _ddmmyyyy(
                                leave['original_date']
                                    ?.toString());
                          }
                        }

                        // Lý do nghỉ
                        String leaveReason =
                            it['leave_reason']?.toString() ?? '';
                        if (leaveReason.isEmpty &&
                            it['leave'] is Map) {
                          final leave = it['leave'] as Map;
                          leaveReason =
                              leave['reason']?.toString() ?? '';
                        }

                        // Room
                        String room = it['_normalized_room']
                                ?.toString()
                                ?.trim() ??
                            '';
                        if (room.isEmpty || room == 'null') {
                          if (it['room'] is Map) {
                            final r = it['room'] as Map;
                            room =
                                r['name']?.toString()?.trim() ??
                                    r['code']
                                        ?.toString()
                                        ?.trim() ??
                                    '';
                          }
                          if (room.isEmpty || room == 'null') {
                            room = it['room_name']
                                    ?.toString()
                                    ?.trim() ??
                                '';
                          }
                          if (room.isEmpty || room == 'null') {
                            final roomStr =
                                it['room']?.toString()?.trim() ??
                                    '';
                            if (roomStr.isNotEmpty &&
                                roomStr != 'null') {
                              room = roomStr;
                            }
                          }
                        }
                        room = room == 'null' ? '' : room;

                        final status = _st(
                            (it['status'] ??
                                    it['_normalized_status'] ??
                                    'PENDING')
                                .toString());

                        final groupedIds =
                            it['_grouped_makeup_request_ids'];
                        final isGrouped = groupedIds is List &&
                            groupedIds.length > 1;
                        final groupCount =
                            isGrouped ? groupedIds.length : 1;

                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  status.color.withOpacity(.3),
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(16),
                            onTap: () => _showDetailDialog(
                              it,
                              subject,
                              className,
                              date,
                              tr,
                              room,
                              originalDate,
                              originalTr,
                              leaveReason,
                              status,
                              isGrouped,
                              groupCount,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subject,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          status.label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor:
                                            status.color
                                                .withOpacity(.15),
                                        side: BorderSide.none,
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 6,
                                          vertical: 0,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Thông tin cơ bản
                                  Container(
                                    padding:
                                        const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius:
                                          BorderRadius.circular(
                                              8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        if (className.isNotEmpty)
                                          _buildInfoRow(
                                              Icons.groups,
                                              'Lớp',
                                              className),
                                        if (date.isNotEmpty)
                                          _buildInfoRow(
                                              Icons
                                                  .calendar_today,
                                              'Ngày dạy bù',
                                              date),
                                        if (tr.isNotEmpty)
                                          _buildInfoRow(
                                              Icons.access_time,
                                              'Thời gian dạy bù',
                                              tr),
                                        if (room.isNotEmpty)
                                          _buildInfoRow(
                                              Icons.room,
                                              'Phòng',
                                              room),
                                      ],
                                    ),
                                  ),

                                  // Thông tin buổi học gốc
                                  if (originalDate.isNotEmpty ||
                                      originalTr.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding:
                                          const EdgeInsets.all(
                                              12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                        border: Border.all(
                                          color: Colors
                                              .orange[200]!
                                              .withOpacity(.5),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .info_outline,
                                                size: 16,
                                                color: Colors
                                                    .orange[700],
                                              ),
                                              const SizedBox(
                                                  width: 6),
                                              Text(
                                                'Buổi học gốc (đã nghỉ)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  color: Colors
                                                      .orange[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 8),
                                          if (originalDate
                                                  .isNotEmpty &&
                                              originalTr
                                                  .isNotEmpty)
                                            Text(
                                              '$originalDate · $originalTr',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors
                                                    .orange[900],
                                              ),
                                            )
                                          else if (originalDate
                                              .isNotEmpty)
                                            Text(
                                              originalDate,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors
                                                    .orange[900],
                                              ),
                                            )
                                          else if (originalTr
                                              .isNotEmpty)
                                            Text(
                                              originalTr,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors
                                                    .orange[900],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Lý do nghỉ
                                  if (leaveReason
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding:
                                          const EdgeInsets.all(
                                              12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                        border: Border.all(
                                          color: Colors
                                              .purple[200]!
                                              .withOpacity(.5),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .note_outlined,
                                                size: 16,
                                                color: Colors
                                                    .purple[700],
                                              ),
                                              const SizedBox(
                                                  width: 6),
                                              Text(
                                                'Lý do nghỉ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  color: Colors
                                                      .purple[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 6),
                                          Text(
                                            leaveReason,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors
                                                  .purple[900],
                                              fontStyle:
                                                  FontStyle
                                                      .italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _selectedStatus = selected ? status : null;
        _applyFilter();
      },
      selectedColor: Theme.of(context)
          .colorScheme
          .primary
          .withOpacity(0.2),
      checkmarkColor:
          Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  void _applyFilter() {
    if (_allItems.isEmpty) {
      _items = _allItems;
      return;
    }

    setState(() {
      if (_selectedStatus == null) {
        _items = _allItems;
      } else {
        _items = _allItems.where((item) {
          final status = (item['status'] ??
                  item['_normalized_status'] ??
                  'PENDING')
              .toString()
              .toUpperCase();
          return status == _selectedStatus!.toUpperCase();
        }).toList();
      }
    });
  }
}
