import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

import 'package:qlgd_lhk/features/auth/view/login_page.dart';
import 'package:qlgd_lhk/features/lecturer/home/lecturer_home_page.dart';
import 'package:qlgd_lhk/features/lecturer/account/lecturer_account_page.dart';
import 'package:qlgd_lhk/features/lecturer/schedule/week_page.dart';
import 'package:qlgd_lhk/features/lecturer/widgets/bottom_nav.dart';

// ✅ import 2 trang xin nghỉ
import 'package:qlgd_lhk/features/lecturer/leave/lecturer_choose_session_page.dart';
import 'package:qlgd_lhk/features/lecturer/leave/lecturer_leave_page.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
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

      // ===== Shell của giảng viên (giữ bottom nav) =====
      ShellRoute(
        builder: (context, state, child) => LecturerBottomNavShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'lecturer_home',
            builder: (context, state) => const LecturerHomePage(),
          ),
          GoRoute(
            path: '/schedule',
            name: 'lecturer_schedule',
            builder: (context, state) => const LecturerWeekPage(),
          ),
          GoRoute(
            path: '/account',
            name: 'lecturer_account',
            builder: (context, state) => const LecturerAccountPage(),
          ),

          // ====== 👇 Route xin nghỉ dạy 👇 ======
          GoRoute(
            path: '/leave/choose',
            name: 'leave_choose_session',
            builder: (context, state) => const LecturerChooseSessionPage(),
          ),
          GoRoute(
            path: '/leave/form',
            name: 'leave_form',
            // nhận buổi học được chọn qua state.extra (Map<String, dynamic>)
            builder: (context, state) =>
                LecturerLeavePage(session: state.extra! as Map<String, dynamic>),
          ),
          // ======================================
        ],
      ),
    ],

    // ===== Redirect theo trạng thái đăng nhập / vai trò =====
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState != null;
      final role = authState?.role;
      final atLogin = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return atLogin ? null : '/login';
      }

      if (atLogin) {
        switch (role) {
          case Role.ADMIN:
            return '/users';            // TODO
          case Role.DAO_TAO:
            return '/schedule/editor';  // TODO
          case Role.GIANG_VIEN:
            return '/home';
          default:
            return '/home';
        }
      }
      return null;
    },
  );
});
