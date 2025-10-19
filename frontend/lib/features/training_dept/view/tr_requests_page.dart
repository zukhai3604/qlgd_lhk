import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class TrainingDepartmentRequestsPage extends StatefulWidget {
  const TrainingDepartmentRequestsPage({super.key});
  @override State<TrainingDepartmentRequestsPage> createState()=>_State();
}

class _State extends State<TrainingDepartmentRequestsPage> with SingleTickerProviderStateMixin {
  final _dio = ApiClient.create().dio;
  late TabController _tab; bool _loading=true;
  List _leave=[], _makeup=[];
  String? _status = 'PENDING'; // filter nhanh

  @override void initState(){ super.initState(); _tab=TabController(length:2,vsync:this); _fetch(); }

  Future<void> _fetch() async {
    setState(()=>_loading=true);
    final params = {'status':_status, 'per_page':100};
    final r1 = await _dio.get('/api/training_department/requests', queryParameters: {...params, 'type':'leave'});
    final r2 = await _dio.get('/api/training_department/requests', queryParameters: {...params, 'type':'makeup'});
    setState(() {
      _leave  = (r1.data['data']?['data'] ?? r1.data['data']) as List? ?? [];
      _makeup = (r2.data['data']?['data'] ?? r2.data['data']) as List? ?? [];
      _loading=false;
    });
  }

  Future<void> _approve(String type, int id) async {
    final path = type=='leave' ? '/api/training_department/leave/$id/approve'
                               : '/api/training_department/makeup/$id/approve';
    await _dio.post(path, data: type=='leave'? {'mark_absent':1}:{'auto_create_schedule':1});
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã phê duyệt'))); _fetch(); }
  }

  Future<void> _reject(String type, int id) async {
    final path = type=='leave' ? '/api/training_department/leave/$id/reject'
                               : '/api/training_department/makeup/$id/reject';
    await _dio.post(path);
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối'))); _fetch(); }
  }

  Future<void> _showDetail(String type, int id) async {
    final res = await _dio.get('/api/training_department/requests/$type/$id');
    final data = res.data['data'] ?? {};
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(const JsonEncoder.withIndent('  ').convert(data)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = const ['PENDING','APPROVED','REJECTED', null]; // null = ALL
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn nghỉ & dạy bù'),
        bottom: TabBar(controller:_tab,tabs:const[Tab(text:'Nghỉ dạy'),Tab(text:'Dạy bù')]),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _status,
              items: statuses.map((s)=>DropdownMenuItem(value:s, child: Text(s??'ALL'))).toList(),
              onChanged: (v){ setState(()=>_status=v); _fetch(); },
            ),
          ),
          const SizedBox(width:8),
        ],
      ),
      body: _loading? const Center(child:CircularProgressIndicator())
        : TabBarView(controller: _tab, children: [
            _list(_leave, 'leave'), _list(_makeup,'makeup')
          ]),
    );
  }

  Widget _list(List data, String type){
    if (data.isEmpty) return const Center(child: Text('Không có dữ liệu'));
        if (data.isEmpty) return const Center(child: Text('Không có dữ liệu'));

        String? _getNested(Map? src, List<String> path) {
          dynamic cur = src;
          for (final k in path) {
            if (cur is Map && cur.containsKey(k)) {
              cur = cur[k];
            } else {
              return null;
            }
          }
          return cur?.toString();
        }

        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, __)=>const Divider(height:1),
          itemBuilder: (_, i){
            final it = data[i] as Map<String, dynamic>? ?? {};
            final subj = type=='leave'
              ? _getNested(it, ['schedule','assignment','subject','name'])
              : _getNested(it, ['leave_request','schedule','assignment','subject','name']);
            final cls  = type=='leave'
              ? _getNested(it, ['schedule','assignment','class_unit','name'])
              : _getNested(it, ['leave_request','schedule','assignment','class_unit','name']);
            final date = type=='leave' ? _getNested(it, ['schedule','session_date']) : _getNested(it, ['suggested_date']);
            final status = (it['status'] ?? '').toString();
            final id = (it['id'] is int) ? it['id'] as int : int.tryParse((it['id'] ?? '').toString()) ?? 0;

            return ListTile(
              leading: Icon(type=='leave' ? Icons.event_busy : Icons.event_available),
              title: Text('${subj ?? 'Môn ?'} — ${cls ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('Ngày: ${date ?? ''} • Trạng thái: $status'),
              trailing: Wrap(spacing:8, children: [
                IconButton(
                  tooltip: 'Từ chối',
                  icon: const Icon(Icons.close),
                  onPressed: status=='PENDING' ? ()=>_reject(type, id) : null,
                ),
                IconButton(
                  tooltip: 'Phê duyệt',
                  icon: const Icon(Icons.check),
                  onPressed: status=='PENDING' ? ()=>_approve(type, id) : null,
                ),
              ]),
              onTap: () => _showDetail(type, id),
            );
          },
        );
  }
}
