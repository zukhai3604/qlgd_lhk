import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/repositories/makeup_history_repository.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/model/repositories/makeup_choose_session_repository.dart';

/// Provider cho MakeupHistoryRepository
final makeupHistoryRepositoryProvider = Provider<MakeupHistoryRepository>((ref) {
  return MakeupHistoryRepositoryImpl();
});

/// Provider cho MakeupChooseSessionRepository
final makeupChooseSessionRepositoryProvider = Provider<MakeupChooseSessionRepository>((ref) {
  return MakeupChooseSessionRepositoryImpl();
});

