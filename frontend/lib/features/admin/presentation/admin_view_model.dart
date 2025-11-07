import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../model/repositories/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repo;
  AdminViewModel({Dio? dio, AdminRepository? repo})
      : _repo = repo ?? AdminRepository(dio: dio);

  bool _isLoadingDashboard = false;
  bool _isLoadingUsers = false;
  Map<String, dynamic>? dashboardStats;
  List<dynamic> users = [];
  Map<String, dynamic>? usersPagination;

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingUsers => _isLoadingUsers;

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    notifyListeners();
    try {
      dashboardStats = await _repo.getDashboardStats();
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({int page = 1, String? search}) async {
    _isLoadingUsers = true;
    notifyListeners();
    try {
      final data = await _repo.fetchUsers(page: page, search: search);
      // Expecting Laravel pagination: data['data'] is list, plus meta links
      users = (data['data'] as List<dynamic>?) ?? [];
      usersPagination = {
        'current_page': data['current_page'] ?? page,
        'last_page': data['last_page'] ?? 1,
        'per_page': data['per_page'] ?? 15,
        'total': data['total'] ?? 0,
      };
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> lockUser(int id) async {
    await _repo.lockUser(id.toString());
    // refresh
    await loadUsers(page: usersPagination?['current_page'] ?? 1);
  }

  Future<void> unlockUser(int id) async {
    await _repo.unlockUser(id.toString());
    await loadUsers(page: usersPagination?['current_page'] ?? 1);
  }
}
