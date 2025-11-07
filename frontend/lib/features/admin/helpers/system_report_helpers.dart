// Helper functions cho System Reports

// Status mapping:
// Database: NEW, IN_REVIEW, ACK, RESOLVED, REJECTED
// Display: Mới, Đang xem xét, Đã xác nhận, Đã giải quyết, Từ chối

class SystemReportHelpers {
  static String getStatusLabel(String status) {
    const labels = {
      'NEW': 'Mới',
      'IN_REVIEW': 'Đang xem xét',
      'ACK': 'Đã xác nhận',
      'RESOLVED': 'Đã giải quyết',
      'REJECTED': 'Từ chối',
    };
    return labels[status] ?? status;
  }

  static Map<String, dynamic> getStatusConfig(String status) {
    switch (status) {
      case 'NEW':
        return {'label': 'MỚI', 'color': const Color(0xFFF97316)}; // orange
      case 'IN_REVIEW':
        return {'label': 'ĐANG XEM XÉT', 'color': const Color(0xFF9333EA)}; // purple
      case 'ACK':
        return {'label': 'ĐÃ XÁC NHẬN', 'color': const Color(0xFF3B82F6)}; // blue
      case 'RESOLVED':
        return {'label': 'ĐÃ GIẢI QUYẾT', 'color': const Color(0xFF10B981)}; // green
      case 'REJECTED':
        return {'label': 'TỪ CHỐI', 'color': const Color(0xFF6B7280)}; // gray
      default:
        return {'label': status, 'color': const Color(0xFF6B7280)};
    }
  }

  static String getCategoryLabel(String category) {
    const labels = {
      'BUG': '🐛 Bug',
      'FEEDBACK': '💬 Góp ý',
      'DATA_ISSUE': '📊 Dữ liệu',
      'PERFORMANCE': '⚡ Hiệu suất',
      'SECURITY': '🔒 Bảo mật',
      'OTHER': '📋 Khác',
    };
    return labels[category] ?? category;
  }

  static Map<String, dynamic> getSeverityConfig(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return {
          'label': 'Nghiêm trọng',
          'color': const Color(0xFFEF4444),
          'icon': const Icon(Icons.error)
        };
      case 'HIGH':
        return {
          'label': 'Cao',
          'color': const Color(0xFFF97316),
          'icon': const Icon(Icons.warning)
        };
      case 'MEDIUM':
        return {
          'label': 'Trung bình',
          'color': const Color(0xFF3B82F6),
          'icon': const Icon(Icons.info)
        };
      default:
        return {
          'label': 'Thấp',
          'color': const Color(0xFF10B981),
          'icon': const Icon(Icons.check_circle)
        };
    }
  }
}
