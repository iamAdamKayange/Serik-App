import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:serik/l10n/app_localization.dart';
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.75)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _content?['appName']?.toString() ?? 'Serik',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _localizedText(_content?['aboutUs']?['body'], locale),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                _LinkTile(
                  title: l10n.tr('Tovuti Rasmi', en: 'Official Website'),
                  value: _content?['websiteUrl']?.toString() ?? 'https://serik.co.tz',
                  icon: Icons.language_rounded,
                  onTap: () => _openUrl(
                    _content?['websiteUrl']?.toString() ?? 'https://serik.co.tz',
                  ),
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  title: _localizedText(_content?['privacyPolicy']?['title'], locale),
                  sections: _content?['privacyPolicy']?['sections'] as List<dynamic>? ?? const [],
                  locale: locale,
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                _PolicySection(
                  title: _localizedText(_content?['termsOfService']?['title'], locale),
                  sections: _content?['termsOfService']?['sections'] as List<dynamic>? ?? const [],
                  locale: locale,
                  isDark: isDark,
                  card: card,
                  text: text,
                  sub: sub,
                  primary: primary,
                ),
                const SizedBox(height: 16),
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

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.card,
    required this.text,
    required this.sub,
    required this.primary,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color card;
  final Color text;
  final Color sub;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Icon(icon, color: primary),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: text)),
      subtitle: Text(value, style: GoogleFonts.poppins(color: sub, fontSize: 12)),
      trailing: Icon(Icons.open_in_new_rounded, color: sub, size: 18),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.sections,
    required this.locale,
    required this.isDark,
    required this.card,
    required this.text,
    required this.sub,
    required this.primary,
  });

  final String title;
  final List<dynamic> sections;
  final String locale;
  final bool isDark;
  final Color card;
  final Color text;
  final Color sub;
  final Color primary;

  String _localized(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value[locale]?.toString() ?? value['en']?.toString() ?? value['sw']?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }

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
          const SizedBox(height: 10),
          ...sections.map((section) {
            final map = section as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_localized(map['title']), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: primary)),
                  const SizedBox(height: 4),
                  Text(_localized(map['body']), style: GoogleFonts.poppins(color: sub, fontSize: 12.5, height: 1.4)),
                ],
              ),
            );
          }),
        ],
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
          Text('support: $supportEmail', style: GoogleFonts.poppins(color: primary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('phone: $supportPhone', style: GoogleFonts.poppins(color: primary, fontSize: 12)),
        ],
      ),
    );
  }
}
