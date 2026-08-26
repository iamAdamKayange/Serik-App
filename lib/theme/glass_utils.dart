import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'app_theme.dart';

/// ============================================================
/// GLASS DECORATION
/// ============================================================

class GlassDecoration extends BoxDecoration {
  GlassDecoration({
    required bool isDark,
    Color? tint,
    double borderRadius = AppTheme.radiusLarge,
    double borderOpacity = 0.18,
    double tintOpacity = 0.08,
    double elevation = 0,
    BoxBorder? border,
    super.gradient,
    super.shape,
  }) : super(
         color: gradient == null
             ? (tint ?? Colors.white).withValues(alpha: tintOpacity)
             : null,
         borderRadius: shape == BoxShape.rectangle
             ? BorderRadius.circular(borderRadius)
             : null,
         border:
             border ??
             Border.all(
               color: Colors.white.withValues(
                 alpha: isDark ? borderOpacity * 0.6 : borderOpacity,
               ),
               width: 1,
             ),
         boxShadow: elevation > 0
             ? [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                   blurRadius: elevation * 4,
                   offset: Offset(0, elevation * 2),
                 ),
               ]
             : null,
       );
}

/// ============================================================
/// GLASS CONTAINER
/// ============================================================
///
/// A reusable glassmorphism container using BackdropFilter.
///
/// Works especially well over:
/// - gradients
/// - images
/// - maps
/// - colorful backgrounds
///
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final Color? tintColor;
  final double tintOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxShape shape;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 18,
    this.borderRadius = AppTheme.radiusLarge,
    this.tintColor,
    this.tintOpacity = 0.08,
    this.borderOpacity = 0.18,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final effectiveTint = tintColor ?? Colors.white;

    final radius = shape == BoxShape.rectangle
        ? BorderRadius.circular(borderRadius)
        : BorderRadius.zero;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: GlassDecoration(
              isDark: isDark,
              tint: effectiveTint,
              borderRadius: borderRadius,
              borderOpacity: borderOpacity,
              tintOpacity: tintOpacity,
              shape: shape,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// GLASS CARD
/// ============================================================
///
/// Premium glass-style card for normal app backgrounds.
///
/// Supports:
/// - accent colors
/// - gradients
/// - shadows
/// - tap interactions
/// - rounded corners
///
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? accentColor;
  final VoidCallback? onTap;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusLarge,
    this.accentColor,
    this.onTap,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final accent = accentColor ?? primary;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),

      // --------------------------------------------------------
      // GLASS GRADIENT
      // --------------------------------------------------------
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                accent.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.03),
              ]
            : [Colors.white, accent.withValues(alpha: 0.04)],
      ),

      // --------------------------------------------------------
      // GLASS BORDER
      // --------------------------------------------------------
      border: Border.all(
        color: isDark
            ? accent.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.90),
        width: 1,
      ),

      // --------------------------------------------------------
      // SHADOW
      // --------------------------------------------------------
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
          blurRadius: elevation * 8,
          offset: Offset(0, elevation * 3),
        ),

        if (!isDark)
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
      ],
    );

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacing16),
      decoration: decoration,
      child: child,
    );

    final wrappedContent = Container(margin: margin, child: content);

    // ----------------------------------------------------------
    // NON-CLICKABLE CARD
    // ----------------------------------------------------------

    if (onTap == null) {
      return wrappedContent;
    }

    // ----------------------------------------------------------
    // CLICKABLE CARD
    // ----------------------------------------------------------

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: wrappedContent,
      ),
    );
  }
}

/// ============================================================
/// GLASS DIVIDER
/// ============================================================
///
/// Thin divider with a subtle gradient glow.
///
class GlassDivider extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;

  const GlassDivider({super.key, this.height = 1, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Container(
      margin:
          margin ?? const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            primary.withValues(alpha: isDark ? 0.25 : 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// GLASS BOTTOM NAVIGATION
/// ============================================================
///
/// Premium glass bottom navigation wrapper.
///
/// Adds:
/// - blur
/// - transparency
/// - rounded top corners
/// - subtle border
/// - shadow
/// - SafeArea support
///
class GlassBottomNav extends StatelessWidget {
  final Widget child;

  const GlassBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppTheme.radiusXLarge),
        topRight: Radius.circular(AppTheme.radiusXLarge),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.82 : 0.90),

            // --------------------------------------------------
            // TOP BORDER
            // --------------------------------------------------
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.55),
                width: 0.7,
              ),
            ),

            // --------------------------------------------------
            // SHADOW
            // --------------------------------------------------
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),

          // ----------------------------------------------------
          // SAFE AREA
          // ----------------------------------------------------
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
