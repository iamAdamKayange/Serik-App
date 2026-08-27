import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============================================================
  // COLORS — SERIK BRANDING THEME
  // ============================================================

  // Primary colors (SERIK green)
  static const Color lightPrimary = Color(0xFF0F8B61);
  static const Color darkPrimary = Color(0xFF46D39A);

  // Background colors
  static const Color lightBackground = Color(0xFFF4F6F5);
  static const Color darkBackground = Color(0xFF0A0F0D);

  // Surface colors
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF141A17);
  static const Color darkSurface2 = Color(0xFF1C2420);

  // Text colors
  static const Color lightText = Color(0xFF111C17);
  static const Color darkText = Color(0xFFF0F5F2);
  static const Color lightSubtext = Color(0xFF5E6E68);
  static const Color darkSubtext = Color(0xFF8A9490);

  // Status colors
  static const Color lightSuccess = Color(0xFF22C55E);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color lightError = Color(0xFFEF4444);
  static const Color darkError = Color(0xFFF87171);
  static const Color lightInfo = Color(0xFF3B82F6);
  static const Color darkInfo = Color(0xFF60A5FA);

  // Legacy colors for compatibility
  static const Color lightSecondary = Color(0xFF2457D6);
  static const Color darkSecondary = Color(0xFF7CA7FF);
  static const Color lightErrorLegacy = Color(0xFFB45309);
  static const Color darkErrorLegacy = Color(0xFFCF6679);
  static const Color lightWarningLegacy = Color(0xFFFF9800);
  static const Color darkWarningLegacy = Color(0xFFFFB74D);
  static const Color lightSuccessLegacy = Color(0xFF4CAF50);
  static const Color darkSuccessLegacy = Color(0xFF81C784);

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
  // RESPONSIVE FONT SIZES
  // ============================================================

  static double getResponsiveFontSize(BuildContext context, {
    required double small,  // For small screens (< 360)
    required double medium, // For medium screens (360-400)
    required double large,  // For large screens (> 400)
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return small;
    if (screenWidth < 400) return medium;
    return large;
  }

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    secondary: lightSecondary,
    background: lightBackground,
    surface: lightSurface,
    onSurface: lightText,
    outline: const Color(0xFFE2E8E5),
    error: lightError,
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
    onSurface: darkText,
    outline: const Color(0xFF26312D),
    error: darkError,
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
    required Color error,
  }) {
    final isDark = brightness == Brightness.dark;
    final subtext = isDark ? darkSubtext : lightSubtext;

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
        error: error,
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
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: 0.3,
        ),
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
        fillColor: isDark ? const Color(0xFF111614) : const Color(0xFFF1F5F3),
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
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: subtext,
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
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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
        labelStyle: GoogleFonts.poppins(color: onSurface),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: subtext,
        backgroundColor: surface,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ========================================================
      // MATERIAL 3 NAVIGATION BAR
      // ========================================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
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

  // ============================================================
  // GETTERS FOR DYNAMIC COLORS
  // ============================================================

  static Color getPrimary(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getSurface2(bool isDark) => isDark ? darkSurface2 : const Color(0xFFF4F6F5);
  static Color getText(bool isDark) => isDark ? darkText : lightText;
  static Color getSubtext(bool isDark) => isDark ? darkSubtext : lightSubtext;
  static Color getSuccess(bool isDark) => isDark ? darkSuccess : lightSuccess;
  static Color getWarning(bool isDark) => isDark ? darkWarning : lightWarning;
  static Color getError(bool isDark) => isDark ? darkError : lightError;
  static Color getInfo(bool isDark) => isDark ? darkInfo : lightInfo;
}
