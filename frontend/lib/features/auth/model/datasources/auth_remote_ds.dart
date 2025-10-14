import 'package:qlgd_lhk/features/auth/model/dtos/auth_user_dto.dart';

abstract class AuthRemoteDS {
  Future<(AuthUserDto, String)> login(String email, String password);
}

/// A mock implementation of the remote data source.
class AuthRemoteDSImpl implements AuthRemoteDS {
  @override
  Future<(AuthUserDto, String)> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network latency

    if (email.startsWith('lecturer@')) {
      final user = AuthUserDto(id: 'lecturer1', email: email, displayName: 'Giảng viên Mẫu', role: 'lecturer');
      final token = 'fake-jwt-token-for-lecturer';
      return (user, token);
    } else if (email.startsWith('training@')) {
      final user = AuthUserDto(id: 'training1', email: email, displayName: 'Cán bộ Đào tạo', role: 'training');
      final token = 'fake-jwt-token-for-training';
      return (user, token);
    } else if (email.startsWith('admin@')) {
      final user = AuthUserDto(id: 'admin1', email: email, displayName: 'Quản trị viên', role: 'admin');
      final token = 'fake-jwt-token-for-admin';
      return (user, token);
    } else {
      // Simulate a 401 Unauthorized error
      throw Exception('Unauthorized');
    }
  }
}
