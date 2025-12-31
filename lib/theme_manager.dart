import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  ThemeManager._internal() {
    _loadTheme();
  }

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  String? _userId;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // If we have a user ID, use user-specific key, otherwise default key
    final key = _userId != null ? 'isDarkMode_$_userId' : 'isDarkMode';
    final isDark = prefs.getBool(key) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setUserId(String? userId) async {
    _userId = userId;
    await _loadTheme();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final key = _userId != null ? 'isDarkMode_$_userId' : 'isDarkMode';
    await prefs.setBool(key, isDark);
  }
}

final themeManager = ThemeManager();
