import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';
import 'package:qlgd_lhk/features/auth/view/login_page.dart';

// --- LECTURER CORE ---
import 'package:qlgd_lhk/features/lecturer/account/lecturer_account_page.dart';
import 'package:qlgd_lhk/features/lecturer/home/presentation/view/lecturer_home_page.dart';
import 'package:qlgd_lhk/features/lecturer/notifications/lecturer_notifications_page.dart';
import 'package:qlgd_lhk/features/lecturer/report/lecturer_report_page.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/presentation/view/schedule_detail_page.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/model/models/schedule_item.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/presentation/view/class_detail_page.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/presentation/view/weekly_schedule_page.dart';
import 'package:qlgd_lhk/features/lecturer/widgets/bottom_nav.dart';
import 'package:qlgd_lhk/features/lecturer/attendance/attendance_page.dart';
import 'package:qlgd_lhk/services/profile_service.dart';

// --- LEAVE ---
// 👉 BỎ alias để dùng trực tiếp tên class, tránh lỗi Method not found
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view/leave_page.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view/leave_history_page.dart';
import 'package:qlgd_lhk/features/lecturer/leave/presentation/view/choose_session_page.dart';

// --- MAKEUP (luồng mới) ---
// 👉 GIỮ alias cho module makeup
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/view/choose_session_page.dart'
    as makeup_pages;
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/view/makeup_page.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/presentation/view/makeup_history_page.dart';

// ======================= Bootstrap Auth =======================

class AuthBootstrapResult {
  const AuthBootstrapResult({required this.isLoggedIn});
  final bool isLoggedIn;
}

final authBootstrapProvider = FutureProvider<AuthBootstrapResult>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token') ??
      await storage.read(key: 'auth_token');
  if (token == null || token.isEmpty) {
    return const AuthBootstrapResult(isLoggedIn: false);
  }

  final profileService = ref.read(profileServiceProvider);
  try {
    final profile = await profileService.getProfile();
    final roleRaw = (profile['role'] ??
            profile['user']?['role'] ??
            profile['data']?['role'])
        ?.toString();
    final role = _mapBackendRole(roleRaw);

    final idRaw = profile['id'] ?? profile['user']?['id'];
    final name = (profile['name'] ??
            profile['full_name'] ??
            profile['user']?['name'])
        ?.toString();
    final email =
        (profile['email'] ?? profile['user']?['email'])?.toString();

    ref.read(authStateProvider.notifier).login(
      token,
      role,
      id: int.tryParse(idRaw?.toString() ?? '') ?? 0,
      name: name,
      email: email,
    );

    return const AuthBootstrapResult(isLoggedIn: true);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'auth_token');
      ref.read(authStateProvider.notifier).logout();
      return const AuthBootstrapResult(isLoggedIn: false);
    }
    rethrow;
  }
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(authBootstrapProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}

// ======================= Router =======================

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            LecturerBottomNavShell(child: child),
        routes: [
          // ---------- Core ----------
          GoRoute(
            path: '/home',
            name: 'lecturer_home',
            builder: (context, state) => const LecturerHomePage(),
          ),
          GoRoute(
            path: '/schedule',
            name: 'lecturer_schedule',
            builder: (context, state) => const WeeklySchedulePage(),
          ),
          GoRoute(
            path: '/schedule/:id',
            name: 'lecturer_schedule_detail',
            builder: (context, state) {
              final idStr = state.pathParameters['id'];
              final id = int.tryParse(idStr ?? '');
              if (id == null) {
                return const Scaffold(
                  body: Center(child: Text('Invalid schedule id')),
                );
              }
              // Nhận session data từ extra nếu có (để hiển thị thông tin đã gộp)
              final sessionData = state.extra is Map<String, dynamic>
                  ? state.extra as Map<String, dynamic>
                  : null;
              return LecturerScheduleDetailPage(
                sessionId: id,
                sessionData: sessionData,
              );
            },
          ),
          GoRoute(
            path: '/attendance/:id',
            name: 'lecturer_attendance',
            builder: (context, state) {
              final idStr = state.pathParameters['id'];
              final id = int.tryParse(idStr ?? '');
              if (id == null) {
                return const Scaffold(
                  body: Center(child: Text('Invalid session id')),
                );
              }
              // Nhận subject, class name và groupedSessionIds từ extra nếu có
              final extra = state.extra is Map<String, dynamic>
                  ? state.extra as Map<String, dynamic>
                  : null;
              
              // Parse groupedSessionIds từ extra
              List<int>? groupedSessionIds;
              if (extra?['groupedSessionIds'] != null) {
                final groupedIdsRaw = extra!['groupedSessionIds'];
                if (groupedIdsRaw is List) {
                  groupedSessionIds = groupedIdsRaw
                      .map((e) => int.tryParse('$e'))
                      .whereType<int>()
                      .toList();
                }
              }
              
              return LecturerAttendancePage(
                sessionId: id,
                subjectName: extra?['subjectName']?.toString(),
                className: extra?['className']?.toString(),
                groupedSessionIds: groupedSessionIds,
              );
            },
          ),
          GoRoute(
            path: '/schedule/class/:id',
            name: 'lecturer_schedule_class_detail',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! ScheduleItem) {
                return const Scaffold(
                  body: Center(child: Text('Session data not found')),
                );
              }
              return ClassDetailPage(item: extra);
            },
          ),
          GoRoute(
            path: '/account',
            name: 'lecturer_account',
            builder: (context, state) => const LecturerAccountPage(),
          ),
          GoRoute(
            path: '/account/edit',
            name: 'account_edit',
            builder: (context, state) =>
                const LecturerAccountPage(initialSheet: AccountSheet.edit),
          ),
          GoRoute(
            path: '/account/change-password',
            name: 'account_change_password',
            builder: (context, state) => const LecturerAccountPage(
              initialSheet: AccountSheet.changePassword,
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'lecturer_notifications',
            builder: (context, state) => const LecturerNotificationsPage(),
          ),
          GoRoute(
            path: '/report',
            name: 'lecturer_report',
            builder: (context, state) => const LecturerReportPage(),
          ),

          // ---------- Leave ----------
          GoRoute(
            path: '/leave/choose',
            name: 'leave_choose_session',
            // Trang chọn buổi học sắp tới để xin nghỉ
            builder: (context, state) => const ChooseSessionPage(),
          ),
          GoRoute(
            path: '/leave/form',
            name: 'leave_form',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! Map<String, dynamic>) {
                return const Scaffold(
                  body: Center(child: Text('Lỗi: Thiếu dữ liệu buổi xin nghỉ.')),
                );
              }
              return LeavePage(session: extra);
            },
          ),
          GoRoute(
            path: '/leave/history',
            name: 'leave_history',
            builder: (context, state) => const LeaveHistoryPage(),
          ),

          // ---------- Makeup (luồng mới) ----------
          // Aliases để tránh 404 khi điều hướng /lecturer/makeup hoặc /makeup
          GoRoute(
            path: '/lecturer/makeup',
            name: 'lecturer_makeup_landing',
            redirect: (context, state) => '/makeup/choose-leave',
          ),
          GoRoute(
            path: '/makeup',
            name: 'makeup_landing',
            redirect: (context, state) => '/makeup/choose-leave',
          ),

          GoRoute(
            // Bước 1: Chọn đơn nghỉ đã duyệt
            path: '/makeup/choose-leave',
            name: 'makeup_choose_leave',
            builder: (context, state) =>
                const makeup_pages.ChooseApprovedLeavePage(),
          ),
          GoRoute(
            // Bước 2: Form dạy bù (nhận buổi gốc/schedule từ bước 1)
            path: '/makeup/form',
            name: 'makeup_form',
            builder: (context, state) {
              final session = state.extra;
              if (session is! Map<String, dynamic>) {
                return const Scaffold(
                  body: Center(child: Text('Lỗi: Không có dữ liệu buổi gốc.')),
                );
              }
              return MakeupPage(contextData: session);
            },
          ),
          GoRoute(
            // Lịch sử dạy bù
            path: '/makeup/history',
            name: 'makeup_history',
            builder: (context, state) => const MakeupHistoryPage(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bootstrap = ref.watch(authBootstrapProvider);
      if (bootstrap.isLoading) return null;
      if (bootstrap.hasError && authState == null) return '/login';

      final isLoggedIn = authState != null;
      final atLogin = state.matchedLocation == '/login';

      if (!isLoggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/home';
      return null;
    },
  );
});

// ======================= Helpers =======================

Role _mapBackendRole(String? raw) {
  switch ((raw ?? '').toUpperCase().trim()) {
    case 'ADMIN':
      return Role.ADMIN;
    case 'DAO_TAO':
    case 'TRAINING_DEPARTMENT':
      return Role.DAO_TAO;
    case 'GIANG_VIEN':
    case 'LECTURER':
      return Role.GIANG_VIEN;
    default:
      return Role.UNKNOWN;
  }
}
