import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:qlgd_lhk/core/api_client.dart';

class TrainingDepartmentSchedulePage extends StatefulWidget {
  const TrainingDepartmentSchedulePage({super.key});
  @override State<TrainingDepartmentSchedulePage> createState()=>_State();
}

class _State extends State<TrainingDepartmentSchedulePage> {
  final _dio = ApiClient.create().dio;
  List _items=[]; bool _loading=true; bool _importing=false;

  @override void initState(){ super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(()=>_loading=true);
    try {
      final res = await _dio.get('/api/training_department/schedules/week', queryParameters:{
        // optional filters
      });
      setState((){
        _items=(res.data['data'] ?? []);
        _loading=false;
      });
    } catch (_) {
      if (!mounted) return;
      setState((){ _items=[]; _loading=false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sinh lịch & Lịch tuần')),
      body: Column(
        children: [
          // Import tools
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhập lịch từ CSV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _importing ? null : _pickAndImport,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_importing ? 'Đang nhập...' : 'Chọn file CSV và nhập'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _copyTemplateLink,
                      child: const Text('Sao chép link tải template'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Cột bắt buộc: subject_code, class_unit_code, date(YYYY-MM-DD), timeslot_code. Tuỳ chọn: room_code, lecturer_email.', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading ? const Center(child:CircularProgressIndicator())
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
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport() async {
    try {
      setState(()=>_importing=true);
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) { setState(()=>_importing=false); return; }
      final file = result.files.first;
      if (file.path == null) { setState(()=>_importing=false); return; }

      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });
      final res = await _dio.post('/api/training_department/schedules/import', data: form);
      final summary = (res.data?['summary'] ?? {}) as Map;
      final created = summary['created'] ?? 0;
      final updated = summary['updated'] ?? 0;
      final skipped = summary['skipped'] ?? 0;
      final errors  = summary['errors'] ?? 0;

      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Kết quả nhập lịch'),
          content: Text('Tạo mới: $created\nCập nhật: $updated\nBỏ qua: $skipped\nLỗi: $errors'),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Đóng')),
          ],
        ));
      }
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi nhập: $e')));
    } finally {
      if (mounted) setState(()=>_importing=false);
    }
  }

  void _copyTemplateLink() {
    final url = _dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '') + '/api/training_department/schedules/import/template';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép link template vào clipboard')));
  }
}
