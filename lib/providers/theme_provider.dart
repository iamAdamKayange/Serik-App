// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'app_locale';

  bool _isDarkMode = false;
  Locale _locale = const Locale('sw');

  ThemeProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _locale = Locale(prefs.getString(_localeKey) ?? 'sw');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
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
