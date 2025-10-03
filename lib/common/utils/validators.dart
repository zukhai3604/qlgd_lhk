class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required.';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Please enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters long.';
    return null;
  }
}
