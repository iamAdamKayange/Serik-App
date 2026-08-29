import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/pages/profile_edit_page.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _loading = true;
  Map<String, dynamic>? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await ApiService.getAppContent();
    if (!mounted) return;
    setState(() {
      _content = content;
      _loading = false;
    });
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  }

  String _localizedText(dynamic value, String languageCode) {
    if (value is Map<String, dynamic>) {
      return value[languageCode]?.toString() ??
          value['en']?.toString() ??
          value['sw']?.toString() ??
          '';
    }
    return value?.toString() ?? '';
  }

  String _localized(dynamic value, String locale) {
    if (value is Map<String, dynamic>) {
      return value[locale]?.toString() ?? value['en']?.toString() ?? value['sw']?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final l10n = AppLocalizations.of(context);
    final primary = isDark ? const Color(0xFF46D39A) : const Color(0xFF0F8B61);
    final bg = isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8);
    final card = isDark ? const Color(0xFF171C1A) : Colors.white;
    final text = isDark ? const Color(0xFFF2F7F4) : const Color(0xFF15201C);
    final sub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.tr('Mipangilio', en: 'Settings')),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Preferences Section
                _SectionHeader(
                  title: l10n.tr('Preferences', en: 'Preferences'),
                  isDark: isDark,
                  text: text,
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  title: l10n.tr('Language', en: 'Language'),
                  subtitle: locale == 'sw' ? 'Kiswahili' : 'English',
                  icon: Icons.language_rounded,
                  onTap: () => _showLanguageDialog(locale, isDark, card, text, sub, primary),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                  trailing: Icon(Icons.chevron_right_rounded, color: sub, size: 20),
                ),
                _SettingsTile(
                  title: l10n.tr('Appearance', en: 'Appearance'),
                  subtitle: l10n.tr('Dark mode', en: 'Dark mode'),
                  icon: Icons.palette_rounded,
                  onTap: () {
                    context.read<ThemeProvider>().toggleTheme();
                  },
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                    activeColor: primary,
                  ),
                ),
                _SettingsTile(
                  title: l10n.tr('Notifications', en: 'Notifications'),
                  subtitle: l10n.tr('Manage notifications', en: 'Manage notifications'),
                  icon: Icons.notifications_rounded,
                  onTap: () {
                    // TODO: Implement notification settings
                  },
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                _SettingsTile(
                  title: l10n.tr('Location', en: 'Location'),
                  subtitle: l10n.tr('Location services', en: 'Location services'),
                  icon: Icons.location_on_rounded,
                  onTap: () {
                    // TODO: Implement location settings
                  },
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                const SizedBox(height: 24),

                // Support Section
                _SectionHeader(
                  title: l10n.tr('Support', en: 'Support'),
                  isDark: isDark,
                  text: text,
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  title: l10n.tr('Help & Support', en: 'Help & Support'),
                  subtitle: l10n.tr('Get help', en: 'Get help'),
                  icon: Icons.help_rounded,
                  onTap: () => _openUrl(
                    _content?['supportUrl']?.toString() ?? 'https://serik.co.tz/support',
                  ),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                _SettingsTile(
                  title: l10n.tr('Terms & Conditions', en: 'Terms & Conditions'),
                  subtitle: l10n.tr('Terms of service', en: 'Terms of service'),
                  icon: Icons.description_rounded,
                  onTap: () => _showPolicyDialog(
                    context,
                    _localizedText(_content?['termsOfService']?['title'], locale),
                    _content?['termsOfService']?['sections'] as List<dynamic>? ?? const [],
                    locale,
                    isDark,
                    card,
                    text,
                    sub,
                    primary,
                  ),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                _SettingsTile(
                  title: l10n.tr('Privacy Policy', en: 'Privacy Policy'),
                  subtitle: l10n.tr('Privacy policy', en: 'Privacy policy'),
                  icon: Icons.privacy_tip_rounded,
                  onTap: () => _showPolicyDialog(
                    context,
                    _localizedText(_content?['privacyPolicy']?['title'], locale),
                    _content?['privacyPolicy']?['sections'] as List<dynamic>? ?? const [],
                    locale,
                    isDark,
                    card,
                    text,
                    sub,
                    primary,
                  ),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                const SizedBox(height: 24),

                // Account Section
                _SectionHeader(
                  title: l10n.tr('Account', en: 'Account'),
                  isDark: isDark,
                  text: text,
                ),
                const SizedBox(height: 8),
                _ActionCard(
                  title: l10n.tr('Hariri Profaili', en: 'Edit Profile'),
                  subtitle: l10n.tr(
                    'Badilisha jina na namba ya simu kutoka backend.',
                    en: 'Update your name and phone number from the backend.',
                  ),
                  icon: Icons.edit_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                  ),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  title: l10n.tr('Logout', en: 'Logout'),
                  subtitle: l10n.tr('Sign out of your account', en: 'Sign out of your account'),
                  icon: Icons.logout_rounded,
                  onTap: () => _showLogoutDialog(context, isDark, card, text, sub, primary),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                  showWarning: true,
                ),
                const SizedBox(height: 24),

                // About
                _AboutCard(
                  title: _localizedText(_content?['aboutUs']?['title'], locale),
                  body: _localizedText(_content?['aboutUs']?['body'], locale),
                  supportEmail: _content?['supportEmail']?.toString() ?? 'support@serik.co.tz',
                  supportPhone: _content?['supportPhone']?.toString() ?? '+255 629 095 954',
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
              ],
            ),
    );
  }

  void _showPolicyDialog(
    BuildContext context,
    String title,
    List<dynamic> sections,
    String locale,
    bool isDark,
    Color card,
    Color text,
    Color sub,
    Color primary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: card,
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: text)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final map = sections[index] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localized(map['title'], locale),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localized(map['body'], locale),
                      style: GoogleFonts.poppins(color: sub, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    bool isDark,
    Color card,
    Color text,
    Color sub,
    Color primary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: card,
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: text),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(color: sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: sub),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
    String currentLocale,
    bool isDark,
    Color card,
    Color text,
    Color sub,
    Color primary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: card,
        title: Text(
          'Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              label: 'Kiswahili',
              code: 'sw',
              isSelected: currentLocale == 'sw',
              onTap: () {
                Navigator.pop(context);
                context.read<ThemeProvider>().setLocale(const Locale('sw'));
              },
              isDark: isDark,
              primary: primary,
            ),
            const SizedBox(height: 8),
            _LanguageOption(
              label: 'English',
              code: 'en',
              isSelected: currentLocale == 'en',
              onTap: () {
                Navigator.pop(context);
                context.read<ThemeProvider>().setLocale(const Locale('en'));
              },
              isDark: isDark,
              primary: primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF26312D) : const Color(0xFFE2E8E5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 20)
            else
              const SizedBox(width: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primary : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isDark,
    required this.text,
  });

  final String title;
  final bool isDark;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: text.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.card,
    required this.text,
    required this.sub,
    required this.primary,
    this.trailing,
    this.showWarning = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color card;
  final Color text;
  final Color sub;
  final Color primary;
  final Widget? trailing;
  final bool showWarning;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: card,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: showWarning ? Colors.red : primary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: showWarning ? Colors.red : text,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                color: sub,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.card,
    required this.text,
    required this.sub,
    required this.primary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color card;
  final Color text;
  final Color sub;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: sub)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: sub),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.title,
    required this.body,
    required this.supportEmail,
    required this.supportPhone,
    required this.isDark,
    required this.card,
    required this.text,
    required this.sub,
    required this.primary,
  });

  final String title;
  final String body;
  final String supportEmail;
  final String supportPhone;
  final bool isDark;
  final Color card;
  final Color text;
  final Color sub;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: text, fontSize: 16)),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.poppins(color: sub, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email_rounded, color: primary, size: 16),
              const SizedBox(width: 8),
              Text(supportEmail, style: GoogleFonts.poppins(color: primary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_rounded, color: primary, size: 16),
              const SizedBox(width: 8),
              Text(supportPhone, style: GoogleFonts.poppins(color: primary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
