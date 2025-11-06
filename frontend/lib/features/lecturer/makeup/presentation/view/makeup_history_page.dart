// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/widgets/tlu_app_bar.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/view_model/makeup_history_view_model.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/utils/makeup_data_helpers.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/widgets/makeup_detail_dialog.dart';

class MakeupHistoryPage extends ConsumerWidget {
  const MakeupHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(makeupHistoryViewModelProvider);
    final viewModel = ref.read(makeupHistoryViewModelProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TluAppBar(title: 'TRƯỜNG ĐẠI HỌC THỦY LỢI'),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 8),
                              child: Text(
                                'Danh sách các đơn đăng ký dạy bù đã gửi. Nhấn vào đơn để xem chi tiết.',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            Expanded(
                              child: state.filteredItems.isEmpty
                                  ? const _EmptyBox()
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      itemCount:
                                          state.filteredItems.length,
                                      itemBuilder: (context, i) {
                                        final item =
                                            state.filteredItems[i];
                                        return _buildMakeupCard(
                                          context,
                                          item,
                                          state.originalItems,
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
    MakeupHistoryViewModel viewModel,
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

  Widget _buildMakeupCard(
    BuildContext context,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> originalItems,
    MakeupHistoryViewModel viewModel,
  ) {
    final tt = Theme.of(context).textTheme;

    // Extract data
    final subject = MakeupDataExtractor.extractSubject(item);
    final className = MakeupDataExtractor.extractClassName(item);
    final room = MakeupDataExtractor.extractRoom(item);
    final time = MakeupDataExtractor.extractTime(item);

    // Format date và time
    final dateStr =
        item['suggested_date'] ?? item['makeup_date'] ?? item['date'];
    final date = DateFormatter.formatDDMMYYYY(dateStr?.toString());

    final timeRange =
        time.startTime.isNotEmpty &&
                time.endTime.isNotEmpty &&
                time.startTime != '--:--' &&
                time.endTime != '--:--'
            ? '${TimeParser.formatHHMM(time.startTime)} - ${TimeParser.formatHHMM(time.endTime)}'
            : '';

    final hasTime =
        timeRange.isNotEmpty && timeRange != '--:-- - --:--';

    // Status info
    final statusStr = (item['status'] ??
            item['_normalized_status'] ??
            'PENDING')
        .toString();

    // Màu viền + icon + text theo trạng thái
    Color borderColor;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (statusStr.toUpperCase()) {
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
        borderColor = Colors.grey.shade300;
        statusColor = Colors.grey.shade700;
        statusIcon = Icons.help_outline;
        statusText = 'Không xác định';
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
          builder: (ctx) => MakeupDetailDialog(
            item: item,
            originalItems: originalItems,
            status: (label: statusText, color: statusColor),
            viewModel: viewModel,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rightMaxWidth = constraints.maxWidth * 0.4;

              return Row(
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
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Phòng học
                        if (room.isNotEmpty && room != '-')
                          Text(
                            'Phòng học: $room',
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Ngày
                        if (date.isNotEmpty)
                          Text(
                            'Ngày: $date',
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ===== BÊN PHẢI: Trạng thái + thời gian + hint =====
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: rightMaxWidth.clamp(120.0, 200.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicator: dùng Wrap để tránh tràn ngang
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            Text(
                              statusText,
                              style: tt.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Icon(
                              statusIcon,
                              size: 16,
                              color: statusColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Thời gian
                        if (hasTime)
                          Text(
                            timeRange,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        else
                          const SizedBox(height: 20),

                        const SizedBox(height: 4),

                        // Hint (luôn hiển thị)
                        Text(
                          'Bấm vào đây để xem chi tiết',
                          style: tt.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
          const Icon(Icons.error_outline,
              size: 48, color: Colors.redAccent),
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
            Icon(Icons.history_toggle_off,
                size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Không có đơn đăng ký dạy bù nào.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
