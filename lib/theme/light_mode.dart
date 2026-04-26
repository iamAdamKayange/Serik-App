import 'package:flutter/material.dart';

final ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF1976D2),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1976D2),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF64B5F6),
  ),
);
