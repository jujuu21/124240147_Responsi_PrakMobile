import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/shared_pref_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    _isLoggedIn = await SharedPrefService.isLoggedIn();
    if (_isLoggedIn) {
      _username = await SharedPrefService.getUsername();
    }
    _isInitialized = true;
    notifyListeners();
  }

  // Register user with local SQLite database
  Future<String?> register(String username, String password) async {
    return await DatabaseHelper.instance.registerUser(username, password);
  }

  // Login user with local SQLite database and persist session with SharedPreferences
  Future<bool> login(String username, String password) async {
    final success = await DatabaseHelper.instance.loginUser(username, password);
    if (success) {
      await SharedPrefService.saveLoginSession(username);
      _isLoggedIn = true;
      _username = username;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Logout and clear session
  Future<void> logout() async {
    await SharedPrefService.clearLoginSession();
    _isLoggedIn = false;
    _username = null;
    notifyListeners();
  }
}
