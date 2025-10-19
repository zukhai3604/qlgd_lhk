import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class TrainingDepartmentSchedulePage extends StatefulWidget {
  const TrainingDepartmentSchedulePage({super.key});
  @override State<TrainingDepartmentSchedulePage> createState()=>_State();
}

class _State extends State<TrainingDepartmentSchedulePage> {
  final _dio = ApiClient.create().dio;
  List _items=[]; bool _loading=true;

  @override void initState(){ super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(()=>_loading=true);
    final res = await _dio.get('/api/training_department/schedules/week', queryParameters:{
      // 'week_start':'2025-10-13',
      // 'lecturer_id':1, 'class_id':1, 'room_id':1,
      // 'semester_label':'HK1', 'academic_year':'2024-2025'
    });
    setState(()=>{ _items=(res.data['data'] ?? []), _loading=false });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch tuần')),
      body: _loading ? const Center(child:CircularProgressIndicator())
        : ListView.separated(
            itemCount:_items.length,
            separatorBuilder: (_, __)=>const Divider(height:1),
            itemBuilder: (_, i){
              final it=_items[i] as Map;
              final sub = it['assignment']?['subject']?['name'] ?? '';
              final cls = it['assignment']?['class_unit']?['name'] ?? '';
              final date= it['session_date'] ?? '';
              final room= it['room']?['code'] ?? '';
              final slot= it['timeslot']?['code'] ?? '';
              final st  = it['status'] ?? '';
              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Text('$sub — $cls', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Ngày $date • Ca $slot • Phòng $room • $st'),
              );
            }),
    );
  }
}
