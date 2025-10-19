import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class TrainingRequestsPage extends StatefulWidget {
  const TrainingRequestsPage({super.key});
  @override
  State<TrainingRequestsPage> createState() => _TrainingRequestsPageState();
}

class _TrainingRequestsPageState extends State<TrainingRequestsPage> with SingleTickerProviderStateMixin {
  final _api = ApiClient.create().dio;
  late TabController _tab;
  List<dynamic> _leave = [], _makeup = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final r1 = await _api.get('/api/training_department/requests', queryParameters:{'type':'leave','per_page':50});
    final r2 = await _api.get('/api/training_department/requests', queryParameters:{'type':'makeup','per_page':50});
    setState(() {
      _leave  = (r1.data['data']['data'] ?? r1.data['data']) as List? ?? [];
      _makeup = (r2.data['data']['data'] ?? r2.data['data']) as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đào tạo — Đơn nghỉ & dạy bù'), bottom: TabBar(controller: _tab, tabs: const [
        Tab(text:'Đơn nghỉ'), Tab(text:'Dạy bù'),
      ])),
      body: _loading ? const Center(child:CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _buildList(_leave, type:'leave'),
              _buildList(_makeup, type:'makeup'),
            ]),
    );
  }

  Widget _buildList(List items, {required String type}) {
    if (items.isEmpty) return const Center(child: Text('Không có dữ liệu'));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height:1),
      itemBuilder: (_, i) {
        final it = items[i];
        final sub   = type=='leave' ? it['schedule']?['assignment']?['subject']?['name'] : it['leave_request']?['schedule']?['assignment']?['subject']?['name'];
        final cls   = type=='leave' ? it['schedule']?['assignment']?['class_unit']?['name'] : it['leave_request']?['schedule']?['assignment']?['class_unit']?['name'];
        final date  = type=='leave' ? it['schedule']?['session_date'] : it['suggested_date'];
        final stat  = it['status'];
        return ListTile(
          title: Text('${sub ?? 'Môn ?'} — ${cls ?? ''}'),
          subtitle: Text('Ngày: $date    Trạng thái: $stat'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDetail(type, it['id']),
        );
      },
    );
  }

  Future<void> _openDetail(String type, int id) async {
    final res = await _api.get('/api/training_department/requests/$type/$id');
    showModalBottomSheet(context: context, builder: (_) {
      final data = res.data['data'] ?? {};
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(const JsonEncoder.withIndent('  ').convert(data)),
        ),
      );
    });
  }
}
