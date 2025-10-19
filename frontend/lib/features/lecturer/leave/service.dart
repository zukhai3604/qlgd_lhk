import 'package:qlgd_lhk/core/api_client.dart';

/// Service class for handling lecturer leave requests.
class LecturerLeaveService {
  final _api = ApiClient.create();

  /// Submits a leave request for a specific session.
  Future<void> submitLeaveRequest({
    required int scheduleId,
    required String reason,
    String? proof,
  }) async {
    // This is the endpoint you need to implement in your backend.
    // It expects a POST request with the schedule ID, reason, and optional proof.
    await _api.dio.post(
      '/api/lecturer/leave-requests', // Ensure this matches your backend route
      data: {
        'schedule_id': scheduleId,
        'reason': reason,
        if (proof != null) 'proof': proof, // Optional proof
      },
    );
  }
}
