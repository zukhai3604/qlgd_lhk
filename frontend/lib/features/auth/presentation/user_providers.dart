import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';

final userRepoProvider = Provider<UserRepository>((ref) => UserRepository());

final meProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.read(userRepoProvider);
  return repo.fetchMe();
});
