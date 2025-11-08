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
                                      // ✅ Tối ưu performance - không dùng itemExtent để card tự điều chỉnh chiều cao
                                      cacheExtent: 500, // Cache items ngoài viewport
                                      addAutomaticKeepAlives: false, // Tiết kiệm memory
                                      addRepaintBoundaries: true, // Tách repaint boundaries
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
          builder: (ctx) => MakeupDetailDialog(
            item: item,
            originalItems: originalItems,
            status: (label: statusText, color: statusColor),
            viewModel: viewModel,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // ✅ Giống home: all(16)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== BÊN TRÁI: Thông tin môn / lớp / ngày / phòng - Giống home card =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tên môn học (in đậm) - giống home
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

              // ===== BÊN PHẢI: Trạng thái + thời gian - Giống home card =====
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
                    // Thời gian - giống home
                    if (hasTime)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          timeRange,
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
                    // Hint (luôn hiển thị)
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
