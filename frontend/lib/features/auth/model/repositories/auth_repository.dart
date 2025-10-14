import 'package:qlgd_lhk/features/auth/model/entities/auth_user.dart';

abstract class AuthRepository {
  Future<(AuthUser user, String token)> login(String email, String password);
  Future<void> logout();
}
