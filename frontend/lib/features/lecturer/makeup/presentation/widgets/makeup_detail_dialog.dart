import 'package:flutter/material.dart';
import 'package:qlgd_lhk/common/widgets/status_chip.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/view_model/makeup_history_view_model.dart';

/// Dialog hiển thị chi tiết đăng ký dạy bù
class MakeupDetailDialog extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> originalItems;
  final ({String label, Color color}) status;
  final MakeupHistoryViewModel viewModel;

  const MakeupDetailDialog({
    super.key,
    required this.item,
    required this.originalItems,
    required this.status,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data sử dụng helper classes
    final subject = MakeupDataExtractor.extractSubject(item);
    final className = MakeupDataExtractor.extractClassName(item);
    final room = MakeupDataExtractor.extractRoom(item);
    final time = MakeupDataExtractor.extractTime(item);
    final originalTime = MakeupDataExtractor.extractOriginalTime(item, originalItems);
    final originalDate = MakeupDataExtractor.extractOriginalDate(item);
    final leaveReason = MakeupDataExtractor.extractLeaveReason(item);

    // Format dates và times
    final dateStr = item['suggested_date'] ?? item['makeup_date'] ?? item['date'];
    final date = DateFormatter.formatDDMMYYYY(dateStr?.toString());
    final originalDateFormatted = DateFormatter.formatDDMMYYYY(originalDate);

    final timeRange = time.startTime.isNotEmpty && time.endTime.isNotEmpty &&
            time.startTime != '--:--' && time.endTime != '--:--'
        ? '${TimeParser.formatHHMM(time.startTime)} - ${TimeParser.formatHHMM(time.endTime)}'
        : '';

    final originalTimeRange = originalTime.startTime.isNotEmpty &&
            originalTime.endTime.isNotEmpty
        ? '${TimeParser.formatHHMM(originalTime.startTime)} - ${TimeParser.formatHHMM(originalTime.endTime)}'
        : '';

    // Extract thông tin buổi học gốc từ leave request
    String origSubject = '';
    String origClass = '';
    String origRoomName = '';

    if (item['leave'] is Map) {
      final leave = item['leave'] as Map;
      if (leave['schedule'] is Map) {
        final schedule = leave['schedule'] as Map;
        if (schedule['assignment'] is Map) {
          final assignment = schedule['assignment'] as Map;
          if (assignment['subject'] is Map) {
            origSubject = (assignment['subject'] as Map)['name']?.toString() ?? '';
          }
          if (assignment['classUnit'] is Map) {
            origClass = (assignment['classUnit'] as Map)['name']?.toString() ?? '';
          }
        }
        if (schedule['room'] is Map) {
          final origRoom = schedule['room'] as Map;
          origRoomName = origRoom['name']?.toString() ?? origRoom['code']?.toString() ?? '';
        }
      }
    }

    return AlertDialog(
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
                StatusChip(
                  label: status.label,
                  color: status.color,
                  compact: false,
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
                '• Môn: ${subject.isNotEmpty && subject != 'Môn học' ? subject : 'Chưa có thông tin'}',
              ),
            ),
            if (className.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• Lớp: $className'),
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
                '• Ngày: ${date.isNotEmpty ? date : 'Chưa có thông tin'}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• Giờ: ${timeRange.isNotEmpty ? timeRange : 'Chưa có thông tin'}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• Phòng: ${room.isNotEmpty ? room : 'Chưa có thông tin'}',
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
                '• Ngày: ${originalDateFormatted.isNotEmpty ? originalDateFormatted : 'Chưa có thông tin'}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• Giờ: ${originalTimeRange.isNotEmpty ? originalTimeRange : 'Chưa có thông tin'}',
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
              leaveReason.isNotEmpty ? leaveReason : 'Chưa có thông tin',
              style: TextStyle(
                fontStyle: leaveReason.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                color: leaveReason.isEmpty ? Colors.grey[600] : null,
              ),
            ),

            // Ghi chú (nếu có)
            if (item['note'] != null && item['note'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Ghi chú:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                item['note'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],

            // Thông báo theo trạng thái
            const SizedBox(height: 16),
            if (status.label == 'Đã duyệt') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.green),
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.red),
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
        if (status.label == 'Chờ duyệt')
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCancelDialog(context, item, viewModel);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    Map<String, dynamic> item,
    MakeupHistoryViewModel viewModel,
  ) async {
    final groupedIds = item['_grouped_makeup_request_ids'];
    final List<int> makeupRequestIds;

    if (groupedIds is List && groupedIds.isNotEmpty) {
      makeupRequestIds = groupedIds
          .map((e) => int.tryParse('$e'))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
    } else {
      final id = item['id'];
      makeupRequestIds = id != null && int.tryParse('$id') != null ? [int.parse('$id')] : [];
    }

    if (makeupRequestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy đơn để hủy')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn đăng ký dạy bù?'),
        content: Text(
          makeupRequestIds.length > 1
              ? 'Bạn có muốn hủy ${makeupRequestIds.length} đơn đăng ký dạy bù liền kề này không?'
              : 'Đơn này đang chờ duyệt. Bạn có muốn hủy không?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = makeupRequestIds.length > 1
          ? await viewModel.cancelMultipleMakeupRequests(makeupRequestIds)
          : await viewModel.cancelMakeupRequest(makeupRequestIds.first);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              makeupRequestIds.length > 1
                  ? 'Đã hủy ${makeupRequestIds.length} đơn đăng ký dạy bù.'
                  : 'Đã hủy đơn đăng ký dạy bù.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi hủy đơn đăng ký dạy bù')),
        );
      }
    }
  }
}

