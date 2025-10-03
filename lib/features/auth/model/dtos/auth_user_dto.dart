import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';
import 'package:qlgd_lhk/features/auth/model/entities/auth_user.dart';

part 'auth_user_dto.freezed.dart';
part 'auth_user_dto.g.dart';

@freezed
class AuthUserDto with _$AuthUserDto {
  const factory AuthUserDto({
    required String id,
    required String email,
    required String displayName,
    required String role, // Role as a string for robust serialization
  }) = _AuthUserDto;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) =>
      _$AuthUserDtoFromJson(json);
}

// Extension method to map DTO to Entity
extension AuthUserDtoX on AuthUserDto {
  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      displayName: displayName,
      role: Role.values.byName(role),
    );
  }
}
