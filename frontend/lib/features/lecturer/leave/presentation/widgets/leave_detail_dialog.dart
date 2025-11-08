import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view_model/leave_history_view_model.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';

/// Dialog hiển thị chi tiết đơn xin nghỉ
class LeaveDetailDialog extends StatelessWidget {
  final Map<String, dynamic> item;
  final LeaveHistoryViewModel viewModel;

  const LeaveDetailDialog({
    super.key,
    required this.item,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? '').toString();
    final statusInfo = _getStatus(status);

    return AlertDialog(
      title: const Text('Chi tiết đơn xin nghỉ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Chip(
                  label: Text(statusInfo.label),
                  backgroundColor: statusInfo.color.withOpacity(0.15),
                  side: BorderSide(color: statusInfo.color),
                  labelStyle: TextStyle(color: statusInfo.color, fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Thông tin buổi học:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if ((item['subject'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• Môn: ${item['subject']}'),
              ),
            if ((item['class_name'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• Lớp: ${item['class_name']}'),
              ),
            if ((item['date'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• Ngày: ${DateFormatter.formatDDMMYYYY(item['date']?.toString())}'),
              ),
            if ((item['start_time'] ?? '').toString().isNotEmpty &&
                (item['end_time'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• Giờ: ${item['start_time']} - ${item['end_time']}'),
              ),
            if ((item['room'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• Phòng: ${item['room']}'),
              ),
            const SizedBox(height: 16),
            if ((item['reason'] ?? '').toString().isNotEmpty) ...[
              const Text('Lý do xin nghỉ:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                item['reason'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
            ],
            if (status == 'REJECTED' && (item['note'] ?? '').toString().isNotEmpty) ...[
              const Text('Lý do từ chối:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              const SizedBox(height: 8),
              Text(
                item['note'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
              ),
            ],
            if (status == 'APPROVED') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đơn đã được duyệt. Bạn có thể đăng ký dạy bù tại trang "Đăng ký dạy bù".',
                        style: TextStyle(fontSize: 12, color: Colors.green),
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
        if (status == 'PENDING')
          TextButton(
            onPressed: () {
              // ✅ KHÔNG đóng dialog ở đây - để _showCancelDialog tự quản lý
              _showCancelDialog(context, item, viewModel);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    Map<String, dynamic> item,
    LeaveHistoryViewModel viewModel,
  ) async {
    final groupedIds = item['_grouped_leave_request_ids'];
    final List<int> leaveRequestIds;

    // ✅ Debug: Log để kiểm tra
    debugPrint('DEBUG LeaveDetailDialog: groupedIds=$groupedIds, item[leave_request_id]=${item['leave_request_id']}, item[id]=${item['id']}, item keys=${item.keys.toList()}');

    if (groupedIds is List && groupedIds.isNotEmpty) {
      leaveRequestIds = groupedIds
          .map((e) => int.tryParse('$e'))
          .whereType<int>()
          .where((id) => id > 0)
          .toList();
      debugPrint('DEBUG LeaveDetailDialog: Using groupedIds, leaveRequestIds=$leaveRequestIds');
    } else {
      // ✅ Thử cả leave_request_id và id (fallback)
      var id = item['leave_request_id'] ?? item['id'];
      debugPrint('DEBUG LeaveDetailDialog: No groupedIds, using item[leave_request_id]=${item['leave_request_id']}, item[id]=${item['id']}, final id=$id');
      leaveRequestIds = id != null && int.tryParse('$id') != null ? [int.parse('$id')] : [];
    }

    debugPrint('DEBUG LeaveDetailDialog: Final leaveRequestIds=$leaveRequestIds');

    if (leaveRequestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy đơn để hủy')),
      );
      return;
    }

    // ✅ Lưu root context và navigator TRƯỚC KHI đóng dialog
    // Sử dụng rootNavigator để lấy context của Scaffold (history page)
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootContext = rootNavigator.context;
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);
    final dialogNavigator = Navigator.of(context);
    
    // ✅ Hiển thị confirm dialog (sử dụng context của detail dialog)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn xin nghỉ?'),
        content: Text(
          leaveRequestIds.length > 1
              ? 'Bạn có muốn hủy đơn xin nghỉ này không?'
              : 'Đơn này đang chờ duyệt. Bạn có muốn hủy không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    // ✅ Nếu user không confirm, return (detail dialog vẫn mở)
    if (confirm != true) {
      debugPrint('DEBUG LeaveDetailDialog: User cancelled');
      return;
    }
    
    debugPrint('DEBUG LeaveDetailDialog: User confirmed, calling cancel API with leaveRequestIds=$leaveRequestIds');
    
    // ✅ Đóng detail dialog trước khi hiển thị loading
    dialogNavigator.pop(); // Đóng detail dialog
    
    // ✅ Kiểm tra root context vẫn còn valid
    if (!rootContext.mounted) {
      debugPrint('DEBUG LeaveDetailDialog: Root context not mounted after closing dialog');
      return;
    }
    
    // ✅ Hiển thị loading indicator trên root context
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (loadingCtx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      debugPrint('DEBUG LeaveDetailDialog: Starting cancel operation...');
      final result = leaveRequestIds.length > 1
          ? await viewModel.cancelMultipleLeaveRequests(leaveRequestIds)
          : await viewModel.cancelLeaveRequest(leaveRequestIds.first);

      debugPrint('DEBUG LeaveDetailDialog: Cancel operation completed, result: success=${result.success}, errorMessage=${result.errorMessage}');

      // ✅ Đóng loading dialog
      if (rootContext.mounted) {
        rootNavigator.pop(); // Đóng loading dialog
      }

      // ✅ Kiểm tra kết quả
      if (result.success) {
        debugPrint('DEBUG LeaveDetailDialog: Cancel successful');
        
        // ✅ Hiển thị success message
        if (rootContext.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Đã hủy đơn xin nghỉ thành công.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('DEBUG LeaveDetailDialog: Cancel failed: ${result.errorMessage}');
        
        // ✅ Hiển thị error message chi tiết từ backend
        if (rootContext.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Lỗi khi hủy đơn xin nghỉ'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('DEBUG LeaveDetailDialog: Exception occurred: $e');
      debugPrint('DEBUG LeaveDetailDialog: StackTrace: $stackTrace');
      
      // ✅ Đóng loading dialog nếu có lỗi
      if (rootContext.mounted) {
        rootNavigator.pop(); // Đóng loading dialog
      }
      
      // ✅ Hiển thị error message
      if (rootContext.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi không mong muốn: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  ({Color color, String label}) _getStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return (color: Colors.green, label: 'Đã duyệt');
      case 'REJECTED':
        return (color: Colors.red, label: 'Từ chối');
      case 'CANCELED':
        return (color: Colors.grey, label: 'Đã hủy');
      case 'PENDING':
        return (color: Colors.orange, label: 'Chờ duyệt');
      default:
        return (color: Colors.grey, label: 'Không xác định');
    }
  }
}

