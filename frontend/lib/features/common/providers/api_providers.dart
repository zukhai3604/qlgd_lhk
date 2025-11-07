import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The set of user roles in the application.
enum Role { ADMIN, DAO_TAO, GIANG_VIEN, UNKNOWN }

/// A simple provider to hold the current user's role.
/// This will be null if the user is not authenticated.
final roleProvider = StateProvider<Role?>((ref) => null);