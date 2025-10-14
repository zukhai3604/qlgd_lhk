import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/auth/model/entities/auth_user.dart';

/// A provider that holds the current authenticated user's state.
/// Returns [AuthUser] if logged in, otherwise null.
final authStateProvider = StateProvider<AuthUser?>((ref) => null);
