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
      appBar: const TluAppBar(title: 'Lịch sử xin nghỉ'),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorBox(message: state.error!, onRetry: () => viewModel.refresh())
              : Column(
                  children: [
                    // Filter bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            _buildFilterChip(context, 'Tất cả', null, state.selectedStatus, viewModel),
                            const SizedBox(width: 8),
                            _buildFilterChip(context, 'Chờ duyệt', 'PENDING', state.selectedStatus, viewModel),
                            const SizedBox(width: 8),
                            _buildFilterChip(context, 'Đã duyệt', 'APPROVED', state.selectedStatus, viewModel),
                            const SizedBox(width: 8),
                            _buildFilterChip(context, 'Từ chối', 'REJECTED', state.selectedStatus, viewModel),
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
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Danh sách các đơn xin nghỉ đã gửi. Nhấn vào đơn để xem chi tiết.',
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            Expanded(
                              child: state.filteredItems.isEmpty
                                  ? const _EmptyBox()
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      itemCount: state.filteredItems.length,
                                      itemBuilder: (context, i) {
                                        final item = state.filteredItems[i];
                                        return _buildLeaveRequestCard(context, item, viewModel);
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => viewModel.filterByStatus(status),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildLeaveRequestCard(
    BuildContext context,
    Map<String, dynamic> item,
    LeaveHistoryViewModel viewModel,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final subject = (item['subject'] ?? 'Môn học').toString();
    final className = (item['class_name'] ?? '').toString();
    final date = DateFormatter.formatDDMMYYYY(item['date']?.toString());
    final start = (item['start_time'] ?? '--:--').toString();
    final end = (item['end_time'] ?? '--:--').toString();
    final room = (item['room'] ?? '').toString();
    final statusInfo = _getStatus(item['status']?.toString() ?? '');

    String timeLine = '$start - $end';
    final hasTime = start != '--:--' && end != '--:--';

    final statusStr = item['status']?.toString().toUpperCase() ?? '';

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
      margin: const EdgeInsets.only(bottom: 10),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== BÊN TRÁI: Thông tin môn / lớp / ngày / phòng =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên môn học (in đậm)
                    Text(
                      subject,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Lớp
                    if (className.isNotEmpty)
                      Text(
                        'Lớp: $className',
                        style: tt.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                    // Phòng học
                    if (room.isNotEmpty)
                      Text(
                        'Phòng học: $room',
                        style: tt.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                    // Ngày
                    if (date.isNotEmpty)
                      Text(
                        'Ngày: $date',
                        style: tt.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),

              // ===== BÊN PHẢI: Trạng thái + thời gian + hint =====
              SizedBox(
                height: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          style: tt.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(statusIcon, size: 16, color: statusColor),
                      ],
                    ),

                    // Thời gian
                    if (hasTime)
                      Text(
                        timeLine,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    else
                      const SizedBox(height: 20),

                    // Hint (luôn hiển thị)
                    Text(
                      'Bấm vào đây để xem chi tiết',
                      style: tt.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.normal,
                      ),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ]),
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
            Icon(Icons.history_toggle_off, size: 56, color: Colors.grey),
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
