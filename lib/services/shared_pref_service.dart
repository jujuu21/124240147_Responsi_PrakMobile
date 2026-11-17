import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUsername = 'logged_in_username';

  // --- Session Management ---
  static Future<void> saveLoginSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setString(keyUsername, username);
  }

  static Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, false);
    await prefs.remove(keyUsername);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUsername);
  }
}
