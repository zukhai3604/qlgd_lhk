import 'package:flutter/material.dart';

/// Status info class
class StatusInfo {
  final String label;
  final Color color;
  
  const StatusInfo(this.label, this.color);
  
  // Standard status mappings
  static StatusInfo approved(ColorScheme cs) => 
      StatusInfo('Đã duyệt', Colors.green);
  
  static StatusInfo rejected(ColorScheme cs) => 
      StatusInfo('Từ chối', Colors.red);
  
  static StatusInfo pending(ColorScheme cs) => 
      StatusInfo('Chờ duyệt', Colors.orange);
  
  static StatusInfo canceled(ColorScheme cs) => 
      StatusInfo('Đã hủy', Colors.grey);
  
  static StatusInfo fromString(String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return approved(cs);
      case 'REJECTED':
        return rejected(cs);
      case 'PENDING':
        return pending(cs);
      case 'CANCELED':
        return canceled(cs);
      default:
        return StatusInfo(status, Colors.blueGrey);
    }
  }
}

/// Standard status chip widget với style đồng bộ
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
  });

  /// Factory constructor từ StatusInfo
  factory StatusChip.fromStatus(StatusInfo status, {bool compact = false}) {
    return StatusChip(
      label: status.label,
      color: status.color,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: 0,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
