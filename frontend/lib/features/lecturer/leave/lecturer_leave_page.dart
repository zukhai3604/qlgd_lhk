import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'service.dart';

class LecturerLeavePage extends StatefulWidget {
  final Map<String, dynamic> session;
  const LecturerLeavePage({super.key, required this.session});

  @override
  State<LecturerLeavePage> createState() => _LecturerLeavePageState();
}

class _LecturerLeavePageState extends State<LecturerLeavePage> {
  final _svc = LecturerLeaveService();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // Correct: Use the 'submitLeaveRequest' method from the service
      await _svc.submitLeaveRequest(
        scheduleId: widget.session['id'] as int,
        reason: _reasonController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi yêu cầu xin nghỉ thành công!')),
      );
      // Go back to the previous screen
      if (context.canPop()) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu xin nghỉ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Môn học: ${widget.session['subject'] ?? 'N/A'}'),
              Text('Thời gian: ${widget.session['date']} • ${widget.session['start_time']}'),
              Text('Phòng: ${widget.session['room'] ?? 'N/A'}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do xin nghỉ',
                  border: OutlineInputBorder(),
                  helperText: 'Vui lòng trình bày rõ lý do của bạn.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập lý do' : null,
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
