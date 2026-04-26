import 'package:flutter/material.dart';

final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF90CAF9),
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF1E1E1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white70),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF90CAF9),
    secondary: Color(0xFF42A5F5),
  ),
);
