// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'app_locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('sw');

  ThemeProvider() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // System mode - will be determined by MediaQuery
    return false; // Default fallback
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    
    if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    _locale = Locale(prefs.getString(_localeKey) ?? 'sw');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final themeString = mode == ThemeMode.dark ? 'dark' : 
                       mode == ThemeMode.light ? 'light' : 'system';
    await prefs.setString(_themeKey, themeString);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    // Cycle through: system -> light -> dark -> system
    if (_themeMode == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'sw'].contains(locale.languageCode)) return;
    _locale = Locale(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, _locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLocale(
      _locale.languageCode == 'sw' ? const Locale('en') : const Locale('sw'),
    );
  }
}
