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

  AuthState copyWith({
    String? token,
    Role? role,
    int? id,
    String? name,
    String? email,
  }) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

// Manages the authentication state throughout the app
class AuthStateNotifier extends StateNotifier<AuthState?> {
  AuthStateNotifier() : super(null);

  // Call this method when the user successfully logs in
  void login(String token, Role role, {int? id, String? name, String? email}) {
    state =
        AuthState(token: token, role: role, id: id, name: name, email: email);
  }

  // Call this method when the user logs out
  void logout() {
    state = null;
  }

  void mergeProfile({String? name, String? email}) {
    patch(name: name, email: email);
  }

  void patch({
    String? token,
    Role? role,
    int? id,
    String? name,
    String? email,
  }) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      token: token ?? current.token,
      role: role ?? current.role,
      id: id ?? current.id,
      name: name ?? current.name,
      email: email ?? current.email,
    );
  }
}

// The global provider for accessing the authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState?>(
  (ref) => AuthStateNotifier(),
);
