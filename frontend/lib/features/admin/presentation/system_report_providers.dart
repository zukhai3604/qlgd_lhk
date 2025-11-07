import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:qlgd_lhk/features/admin/presentation/admin_providers.dart';

// ============ Models ============
class SystemReport {
  final int id;
  final String sourceType;
  final int? reporterUserId;
  final String? reporterName;
  final String? reporterEmail;
  final String contactEmail;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final int? closedBy;
  final String? closerName;
  final List<SystemReportAttachment> attachments;
  final List<SystemReportComment> comments;

  SystemReport({
    required this.id,
    required this.sourceType,
    this.reporterUserId,
    this.reporterName,
    this.reporterEmail,
    required this.contactEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.closedBy,
    this.closerName,
    this.attachments = const [],
    this.comments = const [],
  });

  factory SystemReport.fromJson(Map<String, dynamic> json) {
    return SystemReport(
      id: json['id'] as int,
      sourceType: json['source_type'] as String,
      reporterUserId: json['reporter_user_id'] as int?,
      reporterName: json['reporter']?['name'] as String?,
      reporterEmail: json['reporter']?['email'] as String?,
      contactEmail: json['contact_email'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      closedBy: json['closed_by'] as int?,
      closerName: json['closer']?['name'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => SystemReportAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => SystemReportComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SystemReportAttachment {
  final int id;
  final String fileUrl;
  final String? fileType;
  final DateTime uploadedAt;

  SystemReportAttachment({
    required this.id,
    required this.fileUrl,
    this.fileType,
    required this.uploadedAt,
  });

  factory SystemReportAttachment.fromJson(Map<String, dynamic> json) {
    return SystemReportAttachment(
      id: json['id'] as int,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
}

class SystemReportComment {
  final int id;
  final int? authorUserId;
  final String? authorName;
  final String body;
  final DateTime createdAt;

  SystemReportComment({
    required this.id,
    this.authorUserId,
    this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory SystemReportComment.fromJson(Map<String, dynamic> json) {
    return SystemReportComment(
      id: json['id'] as int,
      authorUserId: json['author_user_id'] as int?,
      authorName: json['author']?['name'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SystemReportStats {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> bySeverity;
  final Map<String, int> byCategory;
  final List<SystemReport> recent;

  SystemReportStats({
    required this.total,
    required this.byStatus,
    required this.bySeverity,
    required this.byCategory,
    required this.recent,
  });

  factory SystemReportStats.fromJson(Map<String, dynamic> json) {
    return SystemReportStats(
      total: json['total'] as int,
      byStatus: Map<String, int>.from(json['by_status'] as Map),
      bySeverity: Map<String, int>.from(json['by_severity'] as Map),
      byCategory: Map<String, int>.from(json['by_category'] as Map),
      recent: (json['recent'] as List<dynamic>)
          .map((e) => SystemReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============ Providers ============

// Statistics Provider
final systemReportStatsProvider = FutureProvider<SystemReportStats>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/api/admin/reports/statistics');
    return SystemReportStats.fromJson(res.data as Map<String, dynamic>);
  } catch (e) {
    throw Exception('Failed to load statistics: $e');
  }
});

// Reports List Provider with filters
class ReportsFilter {
  final String? status;
  final String? severity;
  final String? category;
  final int page;

  ReportsFilter({
    this.status,
    this.severity,
    this.category,
    this.page = 1,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    if (severity != null) params['severity'] = severity;
    if (category != null) params['category'] = category;
    return params;
  }

  ReportsFilter copyWith({
    String? status,
    String? severity,
    String? category,
    int? page,
  }) {
    return ReportsFilter(
      status: status ?? this.status,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      page: page ?? this.page,
    );
  }
}

final reportsFilterProvider = StateProvider<ReportsFilter>((ref) => ReportsFilter());

final systemReportsProvider = FutureProvider.family<Map<String, dynamic>, ReportsFilter>(
  (ref, filter) async {
    final dio = ref.watch(dioProvider);
    try {
      final res = await dio.get(
        '/api/admin/reports',
        queryParameters: filter.toQueryParams(),
      );
      final data = res.data as Map<String, dynamic>;
      return {
        'reports': (data['data'] as List<dynamic>)
            .map((e) => SystemReport.fromJson(e as Map<String, dynamic>))
            .toList(),
        'current_page': data['current_page'] as int,
        'last_page': data['last_page'] as int,
        'total': data['total'] as int,
      };
    } catch (e) {
      throw Exception('Failed to load reports: $e');
    }
  },
);

// Report Detail Provider
final systemReportDetailProvider = FutureProvider.family<SystemReport, int>(
  (ref, id) async {
    final dio = ref.watch(dioProvider);
    try {
      final res = await dio.get('/api/admin/reports/$id');
      return SystemReport.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load report detail: $e');
    }
  },
);

// Update Status
Future<void> updateReportStatus(WidgetRef ref, int reportId, String newStatus) async {
  final dio = ref.read(dioProvider);
  await dio.patch('/api/admin/reports/$reportId/status', data: {
    'status': newStatus,
  });
  // Invalidate để reload
  ref.invalidate(systemReportDetailProvider(reportId));
  ref.invalidate(systemReportsProvider);
  ref.invalidate(systemReportStatsProvider);
}

// Add Comment
Future<void> addReportComment(WidgetRef ref, int reportId, String content) async {
  final dio = ref.read(dioProvider);
  await dio.post('/api/admin/reports/$reportId/comments', data: {
    'content': content,
  });
  // Invalidate để reload
  ref.invalidate(systemReportDetailProvider(reportId));
}
