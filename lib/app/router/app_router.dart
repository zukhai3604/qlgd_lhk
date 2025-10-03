import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlgd_lhk/app/router/route_guards.dart';
import 'package:qlgd_lhk/common/providers/auth_state_provider.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';
import 'package:qlgd_lhk/features/auth/view/login_page.dart';

// --- Placeholder Pages ---
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Schedule Page')));
}

class ScheduleEditorPage extends StatelessWidget {
  const ScheduleEditorPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Schedule Editor Page')));
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Users Page')));
}

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('403 - Unauthorized')));
}

// --- Router Provider ---

final routerProvider = Provider<GoRouter>((ref) {
  // By watching the auth state, the router will be rebuilt whenever the user logs in or out.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    // No refreshListenable is needed because the router is rebuilt on auth changes.
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const SchedulePage(),
      ),
      GoRoute(
        path: '/schedule/editor',
        builder: (context, state) => const ScheduleEditorPage(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersPage(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // Use the authState variable from the provider's scope.
      final isLoggedIn = authState != null;
      final role = authState?.role;
      final location = state.matchedLocation;
      final isAtLogin = location == '/login';

      // If not logged in and not on the login page, redirect to login.
      if (!isLoggedIn && !isAtLogin) {
        return '/login';
      }

      // If logged in and on the login page, redirect to the appropriate home page.
      if (isLoggedIn && isAtLogin) {
        switch (role) {
          case Role.lecturer:
            return '/schedule';
          case Role.training:
            return '/schedule/editor';
          case Role.admin:
            return '/users';
          default:
            return '/schedule'; // Fallback
        }
      }
      
      // Apply role-based guards for protected routes
      if (isLoggedIn) {
         return authGuard(state, role);
      }

      return null; // No redirect needed
    },
  );
});
