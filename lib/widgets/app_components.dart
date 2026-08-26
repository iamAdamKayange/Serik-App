import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_utils.dart';
import '../providers/theme_provider.dart';

/// Premium Stat Card with Glassmorphism effect
class ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.30 : 0.15),
                  color.withValues(alpha: isDark ? 0.15 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A2E28),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium Action Card with gradient + glass overlay
class ModernActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;

  const ModernActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      color.withValues(alpha: 0.85),
                      color.withValues(alpha: 0.65),
                    ]
                  : [color, color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isSmall ? AppTheme.spacing12 : AppTheme.spacing16,
                horizontal: AppTheme.spacing16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isSmall ? 20 : 28,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Loading Indicator with pulsing animation
class ModernLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const ModernLoadingIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final effectiveColor =
        color ?? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary);

    return SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.85 + (value * 0.15), child: child),
          );
        },
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

/// Premium Empty State Widget with Lottie-style animation
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: GlassCard(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                borderRadius: AppTheme.radiusFull,
                accentColor: theme.colorScheme.primary,
                child: Icon(
                  icon,
                  size: 56,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Premium Error State Widget
class ModernErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const ModernErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              borderRadius: AppTheme.radiusFull,
              accentColor: theme.colorScheme.error,
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Premium Section Header with accent bar
class ModernSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const ModernSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primary, primary.withValues(alpha: 0.4)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacing10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                child: Text(
                  trailing!,
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium Search Bar with glassmorphism border
class ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onVoiceSearch;
  final bool isListening;

  const ModernSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onClear,
    this.onChanged,
    this.onVoiceSearch,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final hasText = controller.text.isNotEmpty;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusXLarge,
      accentColor: hasText ? primary : null,
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          color: theme.colorScheme.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: primary, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                ),
              if (onVoiceSearch != null)
                IconButton(
                  icon: Icon(
                    isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: isListening ? theme.colorScheme.error : primary,
                    size: 21,
                  ),
                  onPressed: onVoiceSearch,
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
