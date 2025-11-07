import 'package:dio/dio.dart';
import 'service.dart';

/// Mock Service để test Schedule Detail Page không cần backend
/// Sử dụng khi cần test UI logic mà không phụ thuộc vào API
class LecturerScheduleServiceMock extends LecturerScheduleService {
  // Mock state - có thể thay đổi để test các trường hợp khác nhau
  String _mockStatus = 'PLANNED';
  bool _mockHasAttendance = false;
  String _mockNote = '';
  List<Map<String, dynamic>> _mockMaterials = [];
  
  // Simulate network delay (ms)
  int _networkDelay = 500;
  
  @override
  Future<Map<String, dynamic>> getDetail(int id) async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    
    return {
      'id': id,
      'status': _mockStatus,
      'session_date': '2025-11-08',
      'start_time': '07:00:00',
      'end_time': '08:45:00',
      'note': _mockNote,
      'assignment': {
        'id': 1,
        'subject': {
          'id': 1,
          'name': 'Test Subject',
          'code': 'TEST001',
        },
        'classUnit': {
          'id': 1,
          'name': 'Test Class',
          'code': 'TEST01-K68',
        },
      },
      'room': {
        'id': 1,
        'code': 'A101',
        'name': 'A101',
      },
      'timeslot': {
        'id': 1,
        'start_time': '07:00:00',
        'end_time': '08:45:00',
      },
    };
  }
  
  @override
  Future<List<Map<String, dynamic>>> getMaterials(int sessionId) async {
    await Future.delayed(Duration(milliseconds: _networkDelay ~/ 2));
    return List.from(_mockMaterials);
  }
  
  @override
  Future<bool> checkAttendance(int sessionId) async {
    await Future.delayed(Duration(milliseconds: _networkDelay ~/ 2));
    return _mockHasAttendance;
  }
  
  @override
  Future<Map<String, dynamic>> completeSession(int sessionId) async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    
    // Simulate API response
    if (!_mockHasAttendance) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/lecturer/sessions/$sessionId/finish'),
        response: Response(
          statusCode: 422,
          data: {'message': 'Cần điểm danh trước khi hoàn tất buổi dạy'},
          requestOptions: RequestOptions(path: '/api/lecturer/sessions/$sessionId/finish'),
        ),
      );
    }
    
    if (!['PLANNED', 'TEACHING'].contains(_mockStatus)) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/lecturer/sessions/$sessionId/finish'),
        response: Response(
          statusCode: 422,
          data: {'message': 'Chỉ kết thúc khi buổi dạy đang ở trạng thái PLANNED hoặc TEACHING'},
          requestOptions: RequestOptions(path: '/api/lecturer/sessions/$sessionId/finish'),
        ),
      );
    }
    
    // Update mock status
    _mockStatus = 'DONE';
    
    return {
      'id': sessionId,
      'status': 'DONE',
    };
  }
  
  @override
  Future<void> addMaterial(int sessionId, String title) async {
    await Future.delayed(Duration(milliseconds: _networkDelay ~/ 2));
    _mockMaterials.add({
      'id': _mockMaterials.length + 1,
      'title': title,
      'uploaded_at': DateTime.now().toString(),
      'file_url': null,
      'file_type': null,
    });
  }
  
  @override
  Future<void> uploadMaterialFile({
    required int sessionId,
    required String title,
    required String filePath,
    String? fileType,
  }) async {
    await Future.delayed(Duration(milliseconds: _networkDelay));
    _mockMaterials.add({
      'id': _mockMaterials.length + 1,
      'title': title,
      'uploaded_at': DateTime.now().toString(),
      'file_url': 'https://example.com/files/$title',
      'file_type': fileType ?? 'application/pdf',
    });
  }
  
  @override
  Future<void> submitReport({
    required int sessionId,
    String? status,
    String? note,
    String? content,
    String? issues,
    String? nextPlan,
  }) async {
    await Future.delayed(Duration(milliseconds: _networkDelay ~/ 2));
    if (note != null) {
      _mockNote = note;
    }
  }
  
  // ========== Methods để control mock state (dùng trong debug panel) ==========
  
  /// Set mock status để test các trường hợp khác nhau
  void setMockStatus(String status) {
    _mockStatus = status.toUpperCase();
    print('🔧 Mock: Status changed to $_mockStatus');
  }
  
  /// Set mock attendance để test logic điểm danh
  void setMockHasAttendance(bool has) {
    _mockHasAttendance = has;
    print('🔧 Mock: Attendance changed to $has');
  }
  
  /// Set mock note
  void setMockNote(String note) {
    _mockNote = note;
    print('🔧 Mock: Note changed to "$note"');
  }
  
  /// Add mock material
  void addMockMaterial(String title, {String? fileUrl, String? fileType}) {
    _mockMaterials.add({
      'id': _mockMaterials.length + 1,
      'title': title,
      'uploaded_at': DateTime.now().toString(),
      'file_url': fileUrl,
      'file_type': fileType,
    });
    print('🔧 Mock: Added material "$title"');
  }
  
  /// Clear all mock materials
  void clearMockMaterials() {
    _mockMaterials.clear();
    print('🔧 Mock: Cleared all materials');
  }
  
  /// Set network delay để simulate slow network
  void setNetworkDelay(int milliseconds) {
    _networkDelay = milliseconds;
    print('🔧 Mock: Network delay set to ${milliseconds}ms');
  }
  
  /// Get current mock state (for debugging)
  Map<String, dynamic> getMockState() {
    return {
      'status': _mockStatus,
      'hasAttendance': _mockHasAttendance,
      'note': _mockNote,
      'materialsCount': _mockMaterials.length,
      'networkDelay': _networkDelay,
    };
  }
  
  /// Reset mock state về mặc định
  void resetMockState() {
    _mockStatus = 'PLANNED';
    _mockHasAttendance = false;
    _mockNote = '';
    _mockMaterials.clear();
    _networkDelay = 500;
    print('🔧 Mock: State reset to default');
  }
  
  // ========== Setup Scenarios để test nhanh ==========
  
  /// Scenario 1: PLANNED - Chưa điểm danh
  void setupScenarioPlannedNoAttendance() {
    _mockStatus = 'PLANNED';
    _mockHasAttendance = false;
    _mockNote = '';
    _mockMaterials.clear();
    print('🔧 Mock: Setup scenario - PLANNED (No Attendance)');
  }
  
  /// Scenario 2: PLANNED - Đã điểm danh, có thể kết thúc
  void setupScenarioPlannedWithAttendance() {
    _mockStatus = 'PLANNED';
    _mockHasAttendance = true;
    _mockNote = '';
    _mockMaterials.clear();
    print('🔧 Mock: Setup scenario - PLANNED (With Attendance)');
  }
  
  /// Scenario 3: TEACHING - Đã điểm danh
  void setupScenarioTeachingWithAttendance() {
    _mockStatus = 'TEACHING';
    _mockHasAttendance = true;
    _mockNote = 'Đang trong quá trình giảng dạy';
    _mockMaterials = [
      {'id': 1, 'title': 'Bài giảng chương 1', 'uploaded_at': '2025-11-08', 'file_url': null, 'file_type': null},
    ];
    print('🔧 Mock: Setup scenario - TEACHING (With Attendance)');
  }
  
  /// Scenario 4: DONE - Đã hoàn thành
  void setupScenarioDone() {
    _mockStatus = 'DONE';
    _mockHasAttendance = true;
    _mockNote = 'Buổi học đã hoàn thành';
    _mockMaterials = [
      {'id': 1, 'title': 'Bài giảng chương 1', 'uploaded_at': '2025-11-08', 'file_url': null, 'file_type': null},
      {'id': 2, 'title': 'Bài tập về nhà', 'uploaded_at': '2025-11-08', 'file_url': null, 'file_type': null},
    ];
    print('🔧 Mock: Setup scenario - DONE');
  }
  
  /// Scenario 5: CANCELED - Đã hủy
  void setupScenarioCanceled() {
    _mockStatus = 'CANCELED';
    _mockHasAttendance = false;
    _mockNote = 'Buổi học đã bị hủy';
    _mockMaterials.clear();
    print('🔧 Mock: Setup scenario - CANCELED');
  }
}
