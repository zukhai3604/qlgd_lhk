import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/repositories/makeup_history_repository.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/repositories/providers.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';

part 'makeup_history_view_model.freezed.dart';

@freezed
class MakeupHistoryState with _$MakeupHistoryState {
  const factory MakeupHistoryState({
    @Default(true) bool isLoading,
    String? error,
    @Default([]) List<Map<String, dynamic>> allItems,
    @Default([]) List<Map<String, dynamic>> filteredItems,
    @Default([]) List<Map<String, dynamic>> originalItems, // Lưu items gốc (chưa gộp)
    String? selectedStatus, // null = tất cả, 'PENDING', 'APPROVED', 'REJECTED', 'CANCELED'
  }) = _MakeupHistoryState;
}

final makeupHistoryViewModelProvider =
    StateNotifierProvider<MakeupHistoryViewModel, MakeupHistoryState>((ref) {
  return MakeupHistoryViewModel(ref.read(makeupHistoryRepositoryProvider));
});

class MakeupHistoryViewModel extends StateNotifier<MakeupHistoryState> {
  final MakeupHistoryRepository _repository;

  MakeupHistoryViewModel(this._repository) : super(const MakeupHistoryState()) {
    loadData();
  }

  /// Load dữ liệu ban đầu
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getMakeupRequests();
    result.when(
      success: (list) {
        // Lọc bỏ các đơn đã hủy
        final filtered = list.where((req) {
          final status = (req['status'] ?? '').toString().toUpperCase();
          return status != 'CANCELED';
        }).toList();
        
        // Chuẩn hóa dữ liệu và gộp các đơn liền kề
        final normalized = _normalizeItems(filtered);
        final grouped = _groupConsecutiveMakeupRequests(normalized);

        state = state.copyWith(
          isLoading: false,
          allItems: grouped,
          originalItems: normalized,
        );
        _applyFilter();
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );
  }

  /// Refresh dữ liệu
  Future<void> refresh() async {
    await loadData();
  }

  /// Filter theo trạng thái
  void filterByStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
    _applyFilter();
  }

  /// Áp dụng filter
  void _applyFilter() {
    if (state.selectedStatus == null) {
      state = state.copyWith(filteredItems: state.allItems);
    } else {
      final filtered = state.allItems
          .where((item) =>
              (item['status']?.toString().toUpperCase() ?? '') ==
              state.selectedStatus)
          .toList();
      state = state.copyWith(filteredItems: filtered);
    }
  }

  /// Cancel makeup request
  Future<bool> cancelMakeupRequest(int makeupRequestId) async {
    final result = await _repository.cancelMakeupRequest(makeupRequestId);
    return result.when(
      success: (_) {
        loadData(); // Reload sau khi hủy thành công
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  /// Cancel multiple makeup requests
  Future<bool> cancelMultipleMakeupRequests(List<int> makeupRequestIds) async {
    final result =
        await _repository.cancelMultipleMakeupRequests(makeupRequestIds);
    return result.when(
      success: (_) {
        loadData(); // Reload sau khi hủy thành công
        return true;
      },
      failure: (error) {
        state = state.copyWith(error: error.toString());
        return false;
      },
    );
  }

  /// Chuẩn hóa dữ liệu để dễ so sánh và gộp
  List<Map<String, dynamic>> _normalizeItems(
      List<Map<String, dynamic>> items) {
    return items.map((it) {
      // Sử dụng helper classes để extract data
      final subject = MakeupDataExtractor.extractSubject(it);
      final className = MakeupDataExtractor.extractClassName(it);
      final room = MakeupDataExtractor.extractRoom(it);
      final time = MakeupDataExtractor.extractTime(it);

      final dateStr = it['suggested_date'] ?? it['makeup_date'] ?? it['date'];
      final date = dateStr?.toString().split(' ').first ?? '';

      final status = (it['status'] ?? 'PENDING').toString();

      return {
        ...it,
        '_normalized_subject': subject,
        '_normalized_class_name': className,
        '_normalized_date': date,
        '_normalized_start_time': time.startTime,
        '_normalized_end_time': time.endTime,
        '_normalized_room': room,
        '_normalized_status': status,
      };
    }).toList();
  }

  /// Xác định period từ timeslot code (nếu có)
  int? _getPeriodFromTimeslot(Map<String, dynamic>? timeslot) {
    if (timeslot == null) return null;
    final code = timeslot['code']?.toString() ?? '';
    final match = RegExp(r'CA(\d+)$').firstMatch(code);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Xác định ca từ period hoặc thời gian
  String? _getShiftFromRequest(Map<String, dynamic> request) {
    if (request['timeslot'] is Map) {
      final period = _getPeriodFromTimeslot(
          (request['timeslot'] as Map).cast<String, dynamic>());
      if (period != null) {
        if (period >= 1 && period <= 6) return 'morning';
        if (period >= 7 && period <= 12) return 'afternoon';
        if (period >= 13 && period <= 15) return 'evening';
      }
    }

    final startTime =
        (request['_normalized_start_time'] ?? '--:--').toString();
    if (startTime.isEmpty || startTime == '--:--') return null;

      final minutes = TimeParser.parseToMinutes(startTime);
    if (minutes == null) return null;

    if (minutes >= 420 && minutes < 720) return 'morning';
    if (minutes >= 720 && minutes < 1080) return 'afternoon';
    if (minutes >= 1080) return 'evening';

    return null;
  }

  /// Gộp các đơn đăng ký dạy bù liền kề nhau của cùng môn học thành 1 đơn
  List<Map<String, dynamic>> _groupConsecutiveMakeupRequests(
      List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) return [];

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

      final minutesA = TimeParser.parseToMinutes(startA);
      final minutesB = TimeParser.parseToMinutes(startB);
      if (minutesA == null && minutesB == null) return 0;
      if (minutesA == null) return 1;
      if (minutesB == null) return -1;
      return minutesA.compareTo(minutesB);
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

      final group = <Map<String, dynamic>>[current];
      final groupIndices = <int>[i];

      final currentShift = _getShiftFromRequest(current);

      for (int j = i + 1; j < sorted.length; j++) {
        if (processed.contains(j)) continue;

        final next = sorted[j];
        final nextSubject = (next['_normalized_subject'] ?? '').toString();
        final nextClassName =
            (next['_normalized_class_name'] ?? '').toString();
        final nextDate = (next['_normalized_date'] ?? '').toString();
        final nextStatus = (next['_normalized_status'] ?? '').toString();

        if (subject != nextSubject ||
            className != nextClassName ||
            date != nextDate ||
            status != nextStatus) {
          break;
        }

        final nextShift = _getShiftFromRequest(next);
        if (currentShift != nextShift) {
          break;
        }

        final lastEndTime =
            (group.last['_normalized_end_time'] ?? '--:--').toString();
        final nextStartTime =
            (next['_normalized_start_time'] ?? '--:--').toString();

        final lastEnd = TimeParser.parseToMinutes(lastEndTime);
        final nextStart = TimeParser.parseToMinutes(nextStartTime);

        if (lastEnd == null || nextStart == null) break;

        final gap = nextStart - lastEnd;
        if (gap <= 10 && gap >= 0) {
          group.add(next);
          groupIndices.add(j);
        } else {
          break;
        }
      }

      for (final idx in groupIndices) {
        processed.add(idx);
      }

      if (group.length == 1) {
        result.add(current);
      } else {
        final first = group.first;
        final last = group.last;

        final merged = Map<String, dynamic>.from(first);

        final startTime =
            (first['_normalized_start_time'] ?? '--:--').toString();
        final endTime = (last['_normalized_end_time'] ?? '--:--').toString();

        if (merged['timeslot'] is Map) {
          final ts = Map<String, dynamic>.from(merged['timeslot'] as Map);
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
                ? (endTime.split(':').length == 2 ? '$endTime:00' : endTime)
                : null,
          };
        }

        merged['start_time'] = startTime;
        merged['end_time'] = endTime;
        merged['_normalized_start_time'] = startTime;
        merged['_normalized_end_time'] = endTime;

        String mergedRoom = (first['_normalized_room'] ?? '').toString();
        if (mergedRoom.isEmpty) {
          for (final req in group) {
            final r = (req['_normalized_room'] ?? '').toString();
            if (r.isNotEmpty) {
              mergedRoom = r;
              break;
            }
          }
          if (mergedRoom.isEmpty && merged['room'] is Map) {
            final r = merged['room'] as Map;
            mergedRoom = r['name']?.toString() ?? r['code']?.toString() ?? '';
          }
        }
        merged['_normalized_room'] = mergedRoom;
        if (mergedRoom.isNotEmpty) {
          if (merged['room'] is Map) {
            final r = Map<String, dynamic>.from(merged['room'] as Map);
            r['name'] = mergedRoom;
            r['code'] = mergedRoom;
            merged['room'] = r;
          } else {
            merged['room'] = {'name': mergedRoom, 'code': mergedRoom};
          }
          merged['room_name'] = mergedRoom;
        }

        Object? originalDate = first['original_date'];
        if (originalDate == null && first['leave'] is Map) {
          final leave = first['leave'] as Map;
          originalDate = leave['original_date'];
        }
        merged['original_date'] = originalDate;

        // Thu thập thời gian học gốc từ TẤT CẢ các LEAVE REQUESTS khác nhau trong group
        final leaveRequestsWithTime = <Map<String, dynamic>>[];
        final processedLeaveRequestIds = <int>{};

        for (final req in group) {
          if (req['leave'] is Map) {
            final leave = req['leave'] as Map;
            final leaveRequestId = leave['id'];
            final leaveRequestIdInt =
                leaveRequestId != null ? int.tryParse('$leaveRequestId') : null;

            if (leaveRequestIdInt != null &&
                !processedLeaveRequestIds.contains(leaveRequestIdInt)) {
              String? reqStartTime;
              String? reqEndTime;

              if (leave['schedule'] is Map) {
                final schedule = leave['schedule'] as Map;
                if (schedule['timeslot'] is Map) {
                  final timeslot = schedule['timeslot'] as Map;
                  reqStartTime = timeslot['start_time']?.toString()?.trim();
                  reqEndTime = timeslot['end_time']?.toString()?.trim();
                }
              }

              if (reqStartTime == null ||
                  reqStartTime.isEmpty ||
                  reqEndTime == null ||
                  reqEndTime.isEmpty) {
                if (leave['original_time'] is Map) {
                  final origTime = leave['original_time'] as Map;
                  if (reqStartTime == null || reqStartTime.isEmpty) {
                    reqStartTime = origTime['start_time']?.toString()?.trim();
                  }
                  if (reqEndTime == null || reqEndTime.isEmpty) {
                    reqEndTime = origTime['end_time']?.toString()?.trim();
                  }
                }
              }

              if (reqStartTime == null || reqStartTime.isEmpty) {
                reqStartTime = req['original_start_time']?.toString()?.trim();
              }
              if (reqEndTime == null || reqEndTime.isEmpty) {
                reqEndTime = req['original_end_time']?.toString()?.trim();
              }

              if (reqStartTime != null &&
                  reqStartTime.isNotEmpty &&
                  reqEndTime != null &&
                  reqEndTime.isNotEmpty) {
                leaveRequestsWithTime.add({
                  'start_time': reqStartTime,
                  'end_time': reqEndTime,
                });
                processedLeaveRequestIds.add(leaveRequestIdInt);
              }
            }
          }
        }

        leaveRequestsWithTime.sort((a, b) {
          final startA = TimeParser.parseToMinutes(a['start_time'] as String);
          final startB = TimeParser.parseToMinutes(b['start_time'] as String);
          if (startA == null || startB == null) return 0;
          return startA.compareTo(startB);
        });

        String? firstOriginalStart;
        String? lastOriginalEnd;

        if (leaveRequestsWithTime.isNotEmpty) {
          final first = leaveRequestsWithTime.first;
          final last = leaveRequestsWithTime.last;

          firstOriginalStart = first['start_time'] as String?;
          lastOriginalEnd = last['end_time'] as String?;
        }

        if (firstOriginalStart != null && firstOriginalStart.isNotEmpty) {
          merged['original_start_time'] = firstOriginalStart;
        }
        if (lastOriginalEnd != null && lastOriginalEnd.isNotEmpty) {
          merged['original_end_time'] = lastOriginalEnd;
        }

        merged['leave_reason'] = first['leave_reason'] ??
            first['leave']?['reason'] ??
            '';

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

}

