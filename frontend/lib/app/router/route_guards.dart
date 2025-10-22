import 'package:go_router/go_router.dart';
import 'package:qlgd_lhk/common/providers/role_provider.dart';

/// A simple guard for role-based access. Returns a redirect path if access is denied.
String? authGuard(GoRouterState state, Role? role) {
  final targetPath = state.matchedLocation;

  // Example: Only admins can access paths starting with /users
  if (targetPath.startsWith('/users') && role != Role.ADMIN) {
    return '/unauthorized'; // Or redirect to a 404 page
  }

  // Add more rules here...

  return null; // Access granted
}

/// A utility function to check access without redirecting.
bool canAccess(String path, Role? role) {
  if (path.startsWith('/users') && role != Role.ADMIN) {
    return false;
  }
  return true;
}
