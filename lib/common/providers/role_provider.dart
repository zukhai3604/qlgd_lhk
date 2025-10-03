import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The set of user roles in the application.
enum Role { lecturer, training, admin }

/// A simple provider to hold the current user's role.
/// This will be null if the user is not authenticated.
final roleProvider = StateProvider<Role?>((ref) => null);
