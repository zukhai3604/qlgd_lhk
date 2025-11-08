// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view_model/leave_history_view_model.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/widgets/leave_detail_dialog.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';

class LeaveHistoryPage extends ConsumerWidget {
  const LeaveHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveHistoryViewModelProvider);
    final viewModel = ref.read(leaveHistoryViewModelProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TluAppBar(),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorBox(
                  message: state.error!,
                  onRetry: () => viewModel.refresh(),
                )
              : Column(
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
                            _buildFilterChip(
                              context,
                              'Tất cả',
                              null,
                              state.selectedStatus,
                              viewModel,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              'Chờ duyệt',
                              'PENDING',
                              state.selectedStatus,
                              viewModel,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              'Đã duyệt',
                              'APPROVED',
                              state.selectedStatus,
                              viewModel,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              'Từ chối',
                              'REJECTED',
                              state.selectedStatus,
                              viewModel,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // List content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => viewModel.refresh(),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Danh sách các đơn xin nghỉ đã gửi. Nhấn vào đơn để xem chi tiết.',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            Expanded(
                              child: state.filteredItems.isEmpty
                                  ? const _EmptyBox()
                                  : ListView.builder(
                                      // ✅ Tối ưu performance - không dùng itemExtent để card tự điều chỉnh chiều cao
                                      cacheExtent: 500, // Cache items ngoài viewport
                                      addAutomaticKeepAlives: false, // Tiết kiệm memory
                                      addRepaintBoundaries: true, // Tách repaint boundaries
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      itemCount: state.filteredItems.length,
                                      itemBuilder: (context, i) {
                                        final item =
                                            state.filteredItems[i];
                                        return _buildLeaveRequestCard(
                                          context,
                                          item,
                                          viewModel,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String? status,
    String? selectedStatus,
    LeaveHistoryViewModel viewModel,
  ) {
    final isSelected = selectedStatus == status;
    final primary = Theme.of(context).primaryColor;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => viewModel.filterByStatus(status),
      selectedColor: primary.withOpacity(0.2),
      checkmarkColor: primary,
    );
  }

  Widget _buildLeaveRequestCard(
    BuildContext context,
    Map<String, dynamic> item,
    LeaveHistoryViewModel viewModel,
  ) {
    final tt = Theme.of(context).textTheme;

    final subject = (item['subject'] ?? 'Môn học').toString();
    // ✅ Lấy mã lớp (code) thay vì tên lớp - ưu tiên code
    String className = '';
    
    // Ưu tiên 1: Lấy từ class_code trực tiếp (repository đã extract)
    if (item['class_code'] != null && item['class_code'].toString().isNotEmpty) {
      className = item['class_code'].toString();
    }
    
    // Ưu tiên 2: Lấy từ class_name (repository đã extract với ưu tiên code)
    if (className.isEmpty && item['class_name'] != null && item['class_name'].toString().isNotEmpty) {
      className = item['class_name'].toString();
    }
    
    // Ưu tiên 3: Lấy từ assignment.class_unit.code (fallback)
    if (className.isEmpty && item['assignment'] is Map) {
      final assignment = item['assignment'] as Map;
      final cu = assignment['class_unit'] ?? assignment['classUnit'];
      if (cu is Map) {
        className = (cu['code'] ?? cu['class_code'] ?? cu['name'] ?? '').toString();
      }
    }
    
    // Ưu tiên 4: Lấy từ class_unit trực tiếp
    if (className.isEmpty) {
      final cu = item['class_unit'] ?? item['classUnit'];
      if (cu is Map) {
        className = (cu['code'] ?? cu['class_code'] ?? cu['name'] ?? '').toString();
      }
    }
    final date =
        DateFormatter.formatDDMMYYYY(item['date']?.toString());
    final start = (item['start_time'] ?? '--:--').toString();
    final end = (item['end_time'] ?? '--:--').toString();
    final room = (item['room'] ?? '').toString();
    final statusInfo =
        _getStatus(item['status']?.toString() ?? '');

    final statusStr =
        item['status']?.toString().toUpperCase() ?? '';
    final timeLine = '$start - $end';
    final hasTime = start != '--:--' && end != '--:--';

    // Màu viền + icon + text theo trạng thái
    Color borderColor;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (statusStr) {
      case 'APPROVED':
        borderColor = Colors.green.shade300;
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        statusText = 'Đơn đã được duyệt';
        break;
      case 'REJECTED':
        borderColor = Colors.red.shade300;
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Đơn đã bị từ chối';
        break;
      case 'PENDING':
        borderColor = Colors.orange.shade300;
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.hourglass_top;
        statusText = 'Đơn đang chờ duyệt';
        break;
      default:
        borderColor = statusInfo.color.withOpacity(0.6);
        statusColor = statusInfo.color;
        statusIcon = Icons.help_outline;
        statusText = statusInfo.label;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12), // ✅ Giống home: 12
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => LeaveDetailDialog(
            item: item,
            viewModel: viewModel,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // ✅ Giống home: all(16)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BÊN TRÁI - Giống home card
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject,
                      style: tt.titleLarge?.copyWith( // ✅ Giống home: titleLarge (không override fontSize)
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2, // ✅ Giống home: maxLines 2
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // ✅ Giống home: 8
                    // Phòng học - hiển thị trước như home
                    if (room.isNotEmpty && room != '-')
                      Text(
                        'Phòng học: $room',
                        style: tt.bodyMedium?.copyWith( // ✅ Giống home: bodyMedium (không override fontSize)
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Lớp - Giống home: không có spacing giữa room và class
                    if (className.isNotEmpty && className != 'Lớp')
                      Text(
                        'Lớp: $className',
                        style: tt.bodyMedium?.copyWith( // ✅ Giống home: bodyMedium (không override fontSize)
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2, // ✅ Giống home: maxLines 2
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Ngày - Thêm spacing nhỏ trước ngày
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4), // ✅ Spacing nhỏ trước ngày
                      Text(
                        'Ngày: $date',
                        style: tt.bodyMedium?.copyWith( // ✅ Giống home: bodyMedium
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12), // ✅ Giống home: 12

              // BÊN PHẢI - Giống home card
              SizedBox(
                width: 160, // ✅ Giống home: 160
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 4, // ✅ Giống home: 4
                      runSpacing: 2, // ✅ Giống home: 2
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.end,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120), // ✅ Giống home: 120
                          child: Text(
                            statusText,
                            style: tt.bodySmall?.copyWith( // ✅ Giống home: bodySmall (không override fontSize)
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2, // ✅ Giống home: maxLines 2
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          statusIcon,
                          size: 16, // ✅ Giống home: 16
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // ✅ Giống home: 8
                    if (hasTime)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          timeLine,
                          style: tt.headlineSmall?.copyWith( // ✅ Giống home: headlineSmall
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                            fontSize: 16, // ✅ Giống home: fontSize 16
                          ),
                          textAlign: TextAlign.right,
                        ),
                      )
                    else
                      const SizedBox(height: 24), // ✅ Giống home: 24
                    const SizedBox(height: 4), // ✅ Giống home: 4
                    Text(
                      'Bấm để xem chi tiết',
                      style: tt.bodySmall?.copyWith( // ✅ Giống home: bodySmall (không override fontSize)
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.right, // ✅ Thêm textAlign
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, String label}) _getStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return (color: Colors.green, label: 'Đã duyệt');
      case 'REJECTED':
        return (color: Colors.red, label: 'Từ chối');
      case 'PENDING':
        return (color: Colors.orange, label: 'Chờ duyệt');
      default:
        return (color: Colors.grey, label: 'Không xác định');
    }
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 56,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Không có đơn xin nghỉ nào.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
