import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';
import 'package:qlgd_lhk/features/auth/model/entities/auth_user.dart';

class AuthNotifier extends StateNotifier<AuthUser?> {
  AuthNotifier() : super(null);

  // Correctly create the AuthUser object
  void login(String token, Role role) {
    state = AuthUser(token: token, role: role);
  }

  void logout() {
    state = null;
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  return AuthNotifier();
});
