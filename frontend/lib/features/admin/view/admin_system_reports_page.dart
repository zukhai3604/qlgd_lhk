import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/features/admin/presentation/system_report_providers.dart';
import 'package:intl/intl.dart';

class AdminSystemReportsPage extends ConsumerWidget {
  const AdminSystemReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportsFilterProvider);
    final reportsAsync = ref.watch(systemReportsProvider(filter));
    final statsAsync = ref.watch(systemReportStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Báo cáo Hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(systemReportsProvider);
              ref.invalidate(systemReportStatsProvider);
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Statistics Cards
            statsAsync.when(
              data: (stats) => _StatisticsRow(stats: stats),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),

            // Filters
            _FilterChips(
              currentFilter: filter,
              onFilterChanged: (newFilter) {
                ref.read(reportsFilterProvider.notifier).state = newFilter;
              },
            ),

            const SizedBox(height: 8),

            // Reports List
            Expanded(
              child: reportsAsync.when(
                data: (data) {
                  final reports = data['reports'] as List<SystemReport>;
                  final currentPage = data['current_page'] as int;
                  final lastPage = data['last_page'] as int;

                  if (reports.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Không có báo cáo nào',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: reports.length + (lastPage > 1 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == reports.length) {
                        // Pagination
                        return _PaginationRow(
                          currentPage: currentPage,
                          lastPage: lastPage,
                          onPageChanged: (page) {
                            ref.read(reportsFilterProvider.notifier).state =
                                filter.copyWith(page: page);
                          },
                        );
                      }
                      return _ReportCard(
                        report: reports[index],
                        onTap: () => context.push('/admin/reports/${reports[index].id}'),
                      );
                    },
                  );
                },
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
                        onPressed: () => ref.invalidate(systemReportsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Không highlight item nào vì đây là trang riêng
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

// ============ Statistics Row ============
class _StatisticsRow extends StatelessWidget {
  final SystemReportStats stats;
  const _StatisticsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Tổng số',
            value: stats.total.toString(),
            icon: Icons.folder_outlined,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Mới',
            value: (stats.byStatus['NEW'] ?? 0).toString(),
            icon: Icons.fiber_new_rounded,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Đang xem xét',
            value: (stats.byStatus['IN_REVIEW'] ?? 0).toString(),
            icon: Icons.pending_actions_rounded,
            color: Colors.purple,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Nghiêm trọng',
            value: (stats.bySeverity['CRITICAL'] ?? 0).toString(),
            icon: Icons.warning_rounded,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ Filter Chips ============
class _FilterChips extends StatelessWidget {
  final ReportsFilter currentFilter;
  final ValueChanged<ReportsFilter> onFilterChanged;

  const _FilterChips({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tất cả',
            isSelected: currentFilter.status == null &&
                currentFilter.severity == null &&
                currentFilter.category == null,
            onTap: () => onFilterChanged(ReportsFilter()),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Mới',
            isSelected: currentFilter.status == 'NEW',
            onTap: () => onFilterChanged(
              currentFilter.status == 'NEW'
                ? ReportsFilter() // Reset về "Tất cả" nếu đã selected
                : currentFilter.copyWith(status: 'NEW', category: null, severity: null, page: 1)
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Đang xem xét',
            isSelected: currentFilter.status == 'IN_REVIEW',
            onTap: () => onFilterChanged(
              currentFilter.status == 'IN_REVIEW'
                ? ReportsFilter() // Reset về "Tất cả" nếu đã selected
                : currentFilter.copyWith(status: 'IN_REVIEW', category: null, severity: null, page: 1)
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Đã giải quyết',
            isSelected: currentFilter.status == 'RESOLVED',
            onTap: () => onFilterChanged(
              currentFilter.status == 'RESOLVED' 
                ? ReportsFilter() // Reset về "Tất cả" nếu đã selected
                : currentFilter.copyWith(status: 'RESOLVED', category: null, severity: null, page: 1)
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Bug',
            isSelected: currentFilter.category == 'BUG',
            onTap: () => onFilterChanged(
              currentFilter.category == 'BUG'
                ? ReportsFilter() // Reset về "Tất cả" nếu đã selected
                : currentFilter.copyWith(category: 'BUG', status: null, severity: null, page: 1)
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Nghiêm trọng',
            isSelected: currentFilter.severity == 'CRITICAL',
            onTap: () => onFilterChanged(
              currentFilter.severity == 'CRITICAL'
                ? ReportsFilter() // Reset về "Tất cả" nếu đã selected
                : currentFilter.copyWith(severity: 'CRITICAL', status: null, category: null, page: 1)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ============ Report Card ============
class _ReportCard extends StatelessWidget {
  final SystemReport report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SeverityBadge(severity: report.severity),
                  const SizedBox(width: 8),
                  _CategoryBadge(category: report.category),
                  const Spacer(),
                  _StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.reporterName ?? report.contactEmail,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

// ============ Badges ============
class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final config = _getSeverityConfig(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'], size: 14, color: config['color']),
          const SizedBox(width: 4),
          Text(
            config['label'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getSeverityConfig(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return {'label': 'Nghiêm trọng', 'color': Colors.red, 'icon': Icons.error};
      case 'HIGH':
        return {'label': 'Cao', 'color': Colors.orange, 'icon': Icons.warning};
      case 'MEDIUM':
        return {'label': 'Trung bình', 'color': Colors.blue, 'icon': Icons.info};
      default:
        return {'label': 'Thấp', 'color': Colors.green, 'icon': Icons.check_circle};
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final label = _getCategoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config['color'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config['label'],
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'NEW':
        return {'label': 'MỚI', 'color': Colors.orange};
      case 'IN_REVIEW':
        return {'label': 'ĐANG XÉT', 'color': Colors.purple};
      case 'ACK':
        return {'label': 'XÁC NHẬN', 'color': Colors.blue};
      case 'RESOLVED':
        return {'label': 'GIẢI QUYẾT', 'color': Colors.green};
      case 'REJECTED':
        return {'label': 'TỪ CHỐI', 'color': Colors.grey};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }
}

// ============ Pagination ============
class _PaginationRow extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageChanged;

  const _PaginationRow({
    required this.currentPage,
    required this.lastPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          Text(
            'Trang $currentPage / $lastPage',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: currentPage < lastPage ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
