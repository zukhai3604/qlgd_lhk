import 'package:shared_preferences/shared_preferences.dart';

/// A service for storing non-sensitive key-value data using SharedPreferences.
class AppPrefs {
  final SharedPreferences _prefs;

  AppPrefs(this._prefs);

  // Example of storing the theme preference
  Future<void> saveTheme(String theme) async {
    await _prefs.setString('app_theme', theme);
  }

  String? getTheme() {
    return _prefs.getString('app_theme');
  }
}
