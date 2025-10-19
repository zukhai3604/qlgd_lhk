import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

// Represents the authenticated user's state
class AuthState {
  final String token;
  final Role role;
  // Optional user details
  final int? id;
  final String? name;
  final String? email;

  const AuthState({
    required this.token,
    required this.role,
    this.id,
    this.name,
    this.email,
  });
}

// Manages the authentication state throughout the app
class AuthStateNotifier extends StateNotifier<AuthState?> {
  AuthStateNotifier() : super(null);

  // Call this method when the user successfully logs in
  void login(String token, Role role, {int? id, String? name, String? email}) {
    state = AuthState(token: token, role: role, id: id, name: name, email: email);
  }

  // Call this method when the user logs out
  void logout() {
    state = null;
  }
}

// The global provider for accessing the authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState?>(
  (ref) => AuthStateNotifier(),
);
