import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

/// Thông tin đăng nhập tối thiểu để router/guard hoạt động
class AuthUser {
  final String token;
  final Role role;
  final String? name;
  final String? email;

  const AuthUser({
    required this.token,
    required this.role,
    this.name,
    this.email,
  });
}

/// Notifier quản lý trạng thái đăng nhập
class AuthNotifier extends StateNotifier<AuthUser?> {
  AuthNotifier() : super(null);

  void setSession({
    required String token,
    required Role role,
    String? name,
    String? email,
  }) {
    state = AuthUser(token: token, role: role, name: name, email: email);
  }

  void clear() => state = null;
}

/// Provider để các nơi khác đọc trạng thái đăng nhập hiện tại
final authStateProvider =
StateNotifierProvider<AuthNotifier, AuthUser?>((ref) => AuthNotifier());
