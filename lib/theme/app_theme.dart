import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================================================
  // COLORS — EXISTING GOVERNMENT THEME
  // ============================================================

  static const Color lightPrimary = Color(0xFF0F8B61);
  static const Color lightSecondary = Color(0xFF2457D6);
  static const Color lightBackground = Color(0xFFF7F9F8);
  static const Color lightSurface = Colors.white;

  static const Color darkPrimary = Color(0xFF46D39A);
  static const Color darkSecondary = Color(0xFF7CA7FF);
  static const Color darkBackground = Color(0xFF0D1110);
  static const Color darkSurface = Color(0xFF171C1A);

  // ============================================================
  // SPACING SYSTEM
  // ============================================================

  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ============================================================
  // BORDER RADIUS SYSTEM
  // ============================================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 999.0;

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    secondary: lightSecondary,
    background: lightBackground,
    surface: lightSurface,
    onSurface: const Color(0xFF15201C),
    outline: const Color(0xFFE2E8E5),
  );

  // ============================================================
  // DARK THEME
  // ============================================================

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    secondary: darkSecondary,
    background: darkBackground,
    surface: darkSurface,
    onSurface: const Color(0xFFF2F7F4),
    outline: const Color(0xFF26312D),
  );

  // ============================================================
  // BUILD THEME
  // ============================================================

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color outline,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Background
      scaffoldBackgroundColor: background,
      cardColor: surface,

      // Typography
      fontFamily: GoogleFonts.poppins().fontFamily,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // ========================================================
      // CARD
      // ========================================================
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: outline),
        ),
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: brightness == Brightness.dark
            ? const Color(0xFF111614)
            : const Color(0xFFF1F5F3),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: outline),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: outline),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),

      // ========================================================
      // FILLED BUTTON
      // ========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,

          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing12,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,

          side: BorderSide(color: primary),

          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing12,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // ========================================================
      // CHIP
      // ========================================================
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.14),
        disabledColor: outline,
        side: BorderSide(color: outline),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),

        labelStyle: TextStyle(color: onSurface),
      ),

      // ========================================================
      // OLD BOTTOM NAVIGATION
      // ========================================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: onSurface.withValues(alpha: 0.56),
        backgroundColor: surface,
        elevation: 0,
      ),

      // ========================================================
      // MATERIAL 3 NAVIGATION BAR
      // ========================================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,

        indicatorColor: primary.withValues(alpha: 0.14),

        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );

    // ==========================================================
    // TEXT THEME
    // ==========================================================

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: onSurface, displayColor: onSurface),

      primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
    );
  }
}
