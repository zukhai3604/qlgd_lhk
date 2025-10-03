import 'package:qlgd_lhk/features/auth/model/datasources/auth_remote_ds.dart';
import 'package:qlgd_lhk/features/auth/model/dtos/auth_user_dto.dart';
import 'package:qlgd_lhk/features/auth/model/entities/auth_user.dart';
import 'package:qlgd_lhk/features/auth/model/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDS _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<(AuthUser user, String token)> login(String email, String password) async {
    try {
      final (userDto, token) = await _remoteDataSource.login(email, password);
      // The DTO is mapped to an entity before being returned.
      return (userDto.toEntity(), token);
    } catch (e) {
      // In a real app, you would map specific API errors to custom Failure types
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    // Here you would clear the token from secure storage
  }
}
