import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/features/admin/presentation/system_report_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportDetailPage extends ConsumerStatefulWidget {
  final String reportId;
  const AdminReportDetailPage({Key? key, required this.reportId}) : super(key: key);

  @override
  ConsumerState<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends ConsumerState<AdminReportDetailPage> {
  final _commentController = TextEditingController();
  bool _submittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await updateReportStatus(ref, int.parse(widget.reportId), newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái: $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _submittingComment = true);
    try {
      await addReportComment(ref, int.parse(widget.reportId), _commentController.text);
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm comment')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _submittingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(systemReportDetailProvider(int.parse(widget.reportId)));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Chi tiết Báo cáo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(systemReportDetailProvider(int.parse(widget.reportId))),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _HeaderCard(report: report),
              const SizedBox(height: 16),

              // Description Card
              _DescriptionCard(report: report),
              const SizedBox(height: 16),

              // Attachments (if any)
              if (report.attachments.isNotEmpty) ...[
                _AttachmentsCard(attachments: report.attachments),
                const SizedBox(height: 16),
              ],

              // Status Actions
              _StatusActionsCard(
                currentStatus: report.status,
                onStatusChange: _updateStatus,
              ),
              const SizedBox(height: 16),

              // Comments Section
              _CommentsCard(comments: report.comments),
              const SizedBox(height: 16),

              // Add Comment
              _AddCommentCard(
                controller: _commentController,
                isSubmitting: _submittingComment,
                onSubmit: _addComment,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            context.go('/admin/notifications');
          } else if (index == 2) {
            context.go('/admin/account');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}

// ============ Header Card ============
class _HeaderCard extends StatelessWidget {
  final SystemReport report;
  const _HeaderCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSeverityIcon(report.severity),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Người báo cáo',
              value: report.reporterName ?? 'Khách',
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: report.contactEmail,
            ),
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Loại',
              value: _getCategoryLabel(report.category),
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Thời gian',
              value: DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
            ),
            if (report.closedAt != null) ...[
              _InfoRow(
                icon: Icons.check_circle_outline,
                label: 'Đóng lúc',
                value: DateFormat('dd/MM/yyyy HH:mm').format(report.closedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityIcon(String severity) {
    final config = _getSeverityConfig(severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(config['icon'], color: config['color'], size: 28),
    );
  }

  Map<String, dynamic> _getSeverityConfig(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return {'color': Colors.red, 'icon': Icons.error};
      case 'HIGH':
        return {'color': Colors.orange, 'icon': Icons.warning};
      case 'MEDIUM':
        return {'color': Colors.blue, 'icon': Icons.info};
      default:
        return {'color': Colors.green, 'icon': Icons.check_circle};
    }
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'BUG': 'Lỗi phần mềm',
      'FEEDBACK': 'Góp ý',
      'DATA_ISSUE': 'Vấn đề dữ liệu',
      'PERFORMANCE': 'Hiệu suất',
      'SECURITY': 'Bảo mật',
      'OTHER': 'Khác',
    };
    return labels[category] ?? category;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Description Card ============
class _DescriptionCard extends StatelessWidget {
  final SystemReport report;
  const _DescriptionCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mô tả chi tiết',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Attachments Card ============
class _AttachmentsCard extends StatelessWidget {
  final List<SystemReportAttachment> attachments;
  const _AttachmentsCard({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File đính kèm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...attachments.map((att) => _AttachmentItem(attachment: att)),
          ],
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final SystemReportAttachment attachment;
  const _AttachmentItem({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.fileType?.startsWith('image/') ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            isImage ? Icons.image : Icons.attach_file,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileUrl.split('/').last,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.fileType ?? 'Unknown',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openUrl(attachment.fileUrl),
            tooltip: 'Mở file',
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ============ Status Actions Card ============
class _StatusActionsCard extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onStatusChange;

  const _StatusActionsCard({
    required this.currentStatus,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cập nhật trạng thái',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Trạng thái hiện tại: ${_getStatusLabel(currentStatus)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentStatus == 'NEW')
                  _StatusButton(
                    label: 'Bắt đầu xem xét',
                    icon: Icons.rate_review,
                    color: Colors.purple,
                    onTap: () => onStatusChange('IN_REVIEW'),
                  ),
                if (currentStatus == 'IN_REVIEW') ...[
                  _StatusButton(
                    label: 'Xác nhận',
                    icon: Icons.check_circle,
                    color: Colors.blue,
                    onTap: () => onStatusChange('ACK'),
                  ),
                  _StatusButton(
                    label: 'Từ chối',
                    icon: Icons.cancel,
                    color: Colors.red,
                    onTap: () => onStatusChange('REJECTED'),
                  ),
                ],
                if (currentStatus == 'ACK')
                  _StatusButton(
                    label: 'Đã giải quyết',
                    icon: Icons.done_all,
                    color: Colors.green,
                    onTap: () => onStatusChange('RESOLVED'),
                  ),
                if (currentStatus == 'RESOLVED' || currentStatus == 'REJECTED')
                  _StatusButton(
                    label: 'Mở lại',
                    icon: Icons.refresh,
                    color: Colors.orange,
                    onTap: () => onStatusChange('NEW'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    const labels = {
      'NEW': 'Mới',
      'IN_REVIEW': 'Đang xem xét',
      'ACK': 'Đã xác nhận',
      'RESOLVED': 'Đã giải quyết',
      'REJECTED': 'Từ chối',
    };
    return labels[status] ?? status;
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ============ Comments Card ============
class _CommentsCard extends StatelessWidget {
  final List<SystemReportComment> comments;
  const _CommentsCard({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trao đổi (${comments.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (comments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Chưa có trao đổi nào',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...comments.map((comment) => _CommentItem(comment: comment)),
          ],
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final SystemReportComment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  (comment.authorName ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName ?? 'Admin',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.body,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ============ Add Comment Card ============
class _AddCommentCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _AddCommentCard({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm phản hồi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung phản hồi...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(isSubmitting ? 'Đang gửi...' : 'Gửi phản hồi'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
