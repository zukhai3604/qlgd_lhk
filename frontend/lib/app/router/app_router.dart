import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';
import 'package:qlgd_lhk/features/auth/view/login_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_dashboard_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_users_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_user_detail_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_account_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_notifications_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_create_user_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_system_reports_page.dart';
import 'package:qlgd_lhk/features/admin/view/admin_report_detail_page.dart';
import 'package:qlgd_lhk/features/lecturer/account/lecturer_account_page.dart';
import 'package:qlgd_lhk/features/lecturer/home/lecturer_home_page.dart';
import 'package:qlgd_lhk/features/lecturer/leave/lecturer_choose_session_page.dart';
import 'package:qlgd_lhk/features/lecturer/leave/lecturer_leave_page.dart';
import 'package:qlgd_lhk/features/lecturer/makeup/lecturer_makeup_page.dart';
import 'package:qlgd_lhk/features/lecturer/report/lecturer_report_page.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/models/schedule_item.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/views/class_detail_page.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/views/weekly_schedule_page.dart';
import 'package:qlgd_lhk/features/lecturer/widgets/bottom_nav.dart';
import 'package:qlgd_lhk/services/profile_service.dart';

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
    final name =
        (profile['name'] ?? profile['full_name'] ?? profile['user']?['name'])
            ?.toString();
    final email = (profile['email'] ?? profile['user']?['email'])?.toString();

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
      // Admin routes
      GoRoute(
        path: '/dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin_users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/users/create',
        name: 'adminUserCreate',
        builder: (context, state) => const AdminCreateUserPage(),
      ),
      GoRoute(
        path: '/admin/users/:id',
        name: 'admin_user_detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return AdminUserDetailPage(userId: id);
        },
      ),
      GoRoute(
        path: '/admin/account',
        name: 'adminAccount',
        builder: (context, state) => const AdminAccountPage(),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin_notifications',
        builder: (context, state) => const AdminNotificationsPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'admin_reports',
        builder: (context, state) => const AdminSystemReportsPage(),
      ),
      GoRoute(
        path: '/admin/reports/:id',
        name: 'admin_report_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return AdminReportDetailPage(reportId: id);
        },
      ),
      // Lecturer routes with bottom nav
      ShellRoute(
        builder: (context, state, child) =>
            LecturerBottomNavShell(child: child),
        routes: [
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
            path: '/leave/choose',
            name: 'leave_choose_session',
            builder: (context, state) => const LecturerChooseSessionPage(),
          ),
          GoRoute(
            path: '/leave/form',
            name: 'leave_form',
            builder: (context, state) => LecturerLeavePage(
              session: state.extra! as Map<String, dynamic>,
            ),
          ),
          GoRoute(
            path: '/report',
            name: 'lecturer_report',
            builder: (context, state) => const LecturerReportPage(),
          ),
          GoRoute(
            path: '/makeup-request',
            name: 'lecturer_makeup_request',
            builder: (context, state) => const LecturerMakeupPage(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bootstrap = ref.watch(authBootstrapProvider);
      if (bootstrap.isLoading) {
        return null;
      }

      if (bootstrap.hasError) {
        if (authState == null) {
          return '/login';
        }
      }

      final isLoggedIn = authState != null;
      final atLogin = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return atLogin ? null : '/login';
      }

      if (atLogin) {
        switch (authState!.role) {
          case Role.admin:
            return '/dashboard';
          case Role.training:
            return '/schedule/editor';
          case Role.lecturer:
            return '/home';
          case Role.unknown:
            return '/home';
        }
      }

      return null;
    },
  );
});

Role _mapBackendRole(String? raw) {
  final normalized = (raw ?? '').toLowerCase().trim();
  switch (normalized) {
    case 'admin':
      return Role.admin;
    case 'training':
    case 'dao_tao':
      return Role.training;
    case 'lecturer':
    case 'giang_vien':
      return Role.lecturer;
    default:
      return Role.unknown;
  }
}
