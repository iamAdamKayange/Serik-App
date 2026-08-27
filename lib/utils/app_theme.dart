import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  // Color palette
  static const darkPrimary = Color(0xFF46D39A);
  static const lightPrimary = Color(0xFF0F8B61);
  static const darkBg = Color(0xFF0A0F0D);
  static const lightBg = Color(0xFFF4F6F5);
  static const darkSurface = Color(0xFF141A17);
  static const darkSurface2 = Color(0xFF1C2420);
  static const darkText = Color(0xFFF0F5F2);
  static const lightText = Color(0xFF111C17);
  static const darkSubtext = Color(0xFF8A9490);
  static const lightSubtext = Color(0xFF5E6E68);

  // Status colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      surface: darkSurface,
      background: darkBg,
      error: error,
    ),
    scaffoldBackgroundColor: darkBg,
    fontFamily: AppTypography.fontFamily,
    textTheme: TextTheme(
      displayLarge: AppTypography.headline1.copyWith(color: darkText),
      displayMedium: AppTypography.headline2.copyWith(color: darkText),
      displaySmall: AppTypography.headline3.copyWith(color: darkText),
      headlineLarge: AppTypography.headline4.copyWith(color: darkText),
      headlineMedium: AppTypography.bodyLarge.copyWith(color: darkText),
      headlineSmall: AppTypography.bodyMedium.copyWith(color: darkText),
      titleLarge: AppTypography.headline3.copyWith(color: darkText),
      titleMedium: AppTypography.headline4.copyWith(color: darkText),
      titleSmall: AppTypography.bodyLarge.copyWith(color: darkText),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: darkText),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: darkText),
      bodySmall: AppTypography.bodySmall.copyWith(color: darkSubtext),
      labelLarge: AppTypography.bodyMedium.copyWith(color: darkText),
      labelMedium: AppTypography.bodySmall.copyWith(color: darkText),
      labelSmall: AppTypography.caption.copyWith(color: darkSubtext),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: darkSurface2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkPrimary,
        side: BorderSide(color: darkPrimary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: AppTypography.bodySmall.copyWith(color: darkSubtext),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkPrimary,
      unselectedItemColor: darkSubtext,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      surface: Colors.white,
      background: lightBg,
      error: error,
    ),
    scaffoldBackgroundColor: lightBg,
    fontFamily: AppTypography.fontFamily,
    textTheme: TextTheme(
      displayLarge: AppTypography.headline1.copyWith(color: lightText),
      displayMedium: AppTypography.headline2.copyWith(color: lightText),
      displaySmall: AppTypography.headline3.copyWith(color: lightText),
      headlineLarge: AppTypography.headline4.copyWith(color: lightText),
      headlineMedium: AppTypography.bodyLarge.copyWith(color: lightText),
      headlineSmall: AppTypography.bodyMedium.copyWith(color: lightText),
      titleLarge: AppTypography.headline3.copyWith(color: lightText),
      titleMedium: AppTypography.headline4.copyWith(color: lightText),
      titleSmall: AppTypography.bodyLarge.copyWith(color: lightText),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: lightText),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: lightText),
      bodySmall: AppTypography.bodySmall.copyWith(color: lightSubtext),
      labelLarge: AppTypography.bodyMedium.copyWith(color: lightText),
      labelMedium: AppTypography.bodySmall.copyWith(color: lightText),
      labelSmall: AppTypography.caption.copyWith(color: lightSubtext),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightPrimary,
        side: BorderSide(color: lightPrimary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: AppTypography.bodySmall.copyWith(color: lightSubtext),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: lightPrimary,
      unselectedItemColor: lightSubtext,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // Get theme based on mode
  static ThemeData getTheme(bool isDark) {
    return isDark ? darkTheme : lightTheme;
  }

  // Get colors based on mode
  static Color getPrimary(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color getBackground(bool isDark) => isDark ? darkBg : lightBg;
  static Color getSurface(bool isDark) => isDark ? darkSurface : Colors.white;
  static Color getSurface2(bool isDark) =>
      isDark ? darkSurface2 : const Color(0xFFF4F6F5);
  static Color getText(bool isDark) => isDark ? darkText : lightText;
  static Color getSubtext(bool isDark) => isDark ? darkSubtext : lightSubtext;
}
