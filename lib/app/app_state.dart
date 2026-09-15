// lib/app/app_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';

class AppState extends ChangeNotifier {
  // ===== STATE =====
  bool _isDarkMode = false;
  String _locale = 'ar';
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _userRole;
  bool _supabaseInitialized = false;

  // ===== GETTERS =====
  bool get isDarkMode => _isDarkMode;
  String get locale => _locale;

  /// ✅ Locale object جاهز للاستخدام مع EasyLocalization
  Locale get localeObject {
    switch (_locale) {
      case 'en':
        return const Locale('en');
      case 'zh':
        return const Locale('zh');
      case 'ar':
      default:
        return const Locale('ar');
    }
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get userRole => _userRole;
  bool get supabaseInitialized => _supabaseInitialized;

  bool get isAdmin => _userRole == 'admin';
  bool get isEmployee => _userRole == 'employee';

  // ===== SETTERS =====
  void setSupabaseInitialized(bool initialized) {
    _supabaseInitialized = initialized;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    notifyListeners();
  }

  Future<void> setCurrentUser(AppUser? user) async {
    _currentUser = user;
    _userRole = user?.role ?? 'employee';
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
    }
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _locale = prefs.getString('locale') ?? 'ar';
    notifyListeners();
  }

  Future<void> clearUser() async {
    _currentUser = null;
    _userRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }
}
