import 'package:flutter/material.dart';
import 'package:qlgd_lhk/core/model.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: .5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.item});
  final ScheduleItem item;

  Color _statusColor() {
    if (item.status == ScheduleStatus.done) return const Color(0xFF2ECC71);
    if (item.status == ScheduleStatus.canceled) return const Color(0xFFFF3B30);
    return const Color(0xFF3498DB);
  }

  String _statusLabel() {
    if (item.status == ScheduleStatus.done) return 'Lớp đã hoàn thành';
    if (item.status == ScheduleStatus.canceled) return 'Lớp đã huỷ';
    return 'Lớp đang giảng dạy';
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor();
    return Container(
      decoration: BoxDecoration(border: Border.all(color: c, width: 1.6), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
            child: Text(_statusLabel(), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Phòng học: ${item.room}'),
        Text('Lớp: ${item.className}'),
        const SizedBox(height: 6),
        Text(item.timeLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
