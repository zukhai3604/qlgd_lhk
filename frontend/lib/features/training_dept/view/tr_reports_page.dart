import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class TrainingDepartmentReportsPage extends StatefulWidget {
  const TrainingDepartmentReportsPage({super.key});
  @override State<TrainingDepartmentReportsPage> createState()=>_State();
}

class _State extends State<TrainingDepartmentReportsPage> {
  final _dio = ApiClient.create().dio;
  final _semCtl = TextEditingController(text: 'HK1');
  final _yearCtl= TextEditingController(text: '2024-2025');

  Map _overview={}; List _bySubject=[], _byLecturer=[], _byClass=[];
  bool _loading=false;

  Future<void> _load() async {
    setState(()=>_loading=true);
    final q = {'semester_label': _semCtl.text.trim(), 'academic_year': _yearCtl.text.trim()};
    try {
      final o = await _dio.get('/api/training_department/reports/overview',          queryParameters:q);
      final s = await _dio.get('/api/training_department/reports/subject-progress',  queryParameters:q);
      final l = await _dio.get('/api/training_department/reports/lecturer-progress', queryParameters:q);
      final c = await _dio.get('/api/training_department/reports/class-progress',    queryParameters:q);
      setState(() {
        _overview = (o.data['data'] as List).isNotEmpty ? (o.data['data'] as List).first : {};
        _bySubject = s.data['data'] ?? [];
        _byLecturer= l.data['data'] ?? [];
        _byClass   = c.data['data'] ?? [];
      });
    } finally {
      if (mounted) setState(()=>_loading=false);
    }
  }

  @override void initState(){ super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo học kỳ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller:_semCtl, decoration: const InputDecoration(labelText:'Học kỳ'))),
            const SizedBox(width:12),
            Expanded(child: TextField(controller:_yearCtl, decoration: const InputDecoration(labelText:'Năm học'))),
            const SizedBox(width:12),
            ElevatedButton(onPressed:_loading?null:_load, child: const Text('Lọc'))
          ]),
          const SizedBox(height:12),
          if (_loading) const LinearProgressIndicator(),

          if (!_loading) ...[
            Card(child: ListTile(
              title: const Text('Tổng quan'),
              subtitle: Text('Buổi: ${_overview['total_sessions'] ?? '-'}  •  Dạy: ${_overview['taught_count'] ?? '-'}  •  Bù: ${_overview['makeup_count'] ?? '-'}  •  Nghỉ: ${_overview['absent_count'] ?? '-'}  •  %HT: ${_overview['completion_percent'] ?? '-'}'),
            )),
            const SizedBox(height:8),
            Expanded(child: DefaultTabController(
              length: 3,
              child: Column(children: [
                const TabBar(tabs:[Tab(text:'Theo môn'),Tab(text:'Theo GV'),Tab(text:'Theo lớp')]),
                Expanded(child: TabBarView(children: [
                  _table(_bySubject, ['subject_code','subject_name','total_sessions','completion_percent']),
                  _table(_byLecturer,['lecturer_name','total_sessions','completion_percent']),
                  _table(_byClass,   ['class_code','class_name','total_sessions','completion_percent']),
                ]))
              ]),
            ))
          ]
        ]),
      ),
    );
  }

  Widget _table(List rows, List cols){
    if (rows.isEmpty) return const Center(child: Text('Không có dữ liệu'));
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __)=>const Divider(height:1),
      itemBuilder: (_, i){
        final r = rows[i] as Map;
        return ListTile(
          title: Text(cols.take(2).map((k)=> (r[k]??'').toString()).join(' — ')),
          subtitle: Text(cols.skip(2).map((k)=> '$k: ${r[k]}').join(' • ')),
        );
      },
    );
  }
}
