import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

part 'auth_user.freezed.dart';

@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String token, // Added token
    required Role role,
    // These fields are optional now
    String? id,
    String? email,
    String? displayName,
  }) = _AuthUser;
}
