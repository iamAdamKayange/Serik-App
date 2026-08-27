import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
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

  // Font family
  static String get fontFamily => 'Poppins';

  // Responsive font sizes based on screen width
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

  // Font styles
  static TextStyle get headline1 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );

  static TextStyle get headline2 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle get headline3 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle get headline4 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get overline => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  // Responsive headline styles
  static TextStyle responsiveHeadline1(BuildContext context) {
    final fontSize = getResponsiveFontSize(context,
      small: 20, medium: 22, large: 24);
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    );
  }

  static TextStyle responsiveHeadline2(BuildContext context) {
    final fontSize = getResponsiveFontSize(context,
      small: 16, medium: 18, large: 20);
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }

  static TextStyle responsiveHeadline3(BuildContext context) {
    final fontSize = getResponsiveFontSize(context,
      small: 15, medium: 17, large: 18);
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }

  static TextStyle responsiveBodyLarge(BuildContext context) {
    final fontSize = getResponsiveFontSize(context,
      small: 13, medium: 14, large: 15);
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle responsiveBodyMedium(BuildContext context) {
    final fontSize = getResponsiveFontSize(context,
      small: 12, medium: 13, large: 14);
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle responsiveBodySmall(BuildContext context) {
    final fontSize = getResponsiveFontSize(context,
      small: 11, medium: 12, large: 13);
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );
  }

  // Theme-based text styles
  static TextStyle getThemeHeadline1(bool isDark) => headline1.copyWith(
    color: isDark ? darkText : lightText,
  );

  static TextStyle getThemeHeadline2(bool isDark) => headline2.copyWith(
    color: isDark ? darkText : lightText,
  );

  static TextStyle getThemeBody(bool isDark) => bodyMedium.copyWith(
    color: isDark ? darkText : lightText,
  );

  static TextStyle getThemeSubtext(bool isDark) => bodySmall.copyWith(
    color: isDark ? darkSubtext : lightSubtext,
  );

  static TextStyle getThemeCaption(bool isDark) => caption.copyWith(
    color: isDark ? darkSubtext : lightSubtext,
  );
}
