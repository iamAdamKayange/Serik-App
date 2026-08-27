import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import '../providers/theme_provider.dart';
import '../model/tenant_model.dart';
import '../widgets/custom_dialogs.dart';

class TenantsPage extends StatelessWidget {
  final List<TenantData> tenants;
  final VoidCallback onAddTenant;

  const TenantsPage({super.key, required this.tenants, required this.onAddTenant});

  static const _darkPrimary  = Color(0xFF46D39A);
  static const _lightPrimary = Color(0xFF0F8B61);
  static const _darkBg       = Color(0xFF0A0F0D);
  static const _lightBg      = Color(0xFFF4F6F5);
  static const _darkSurface  = Color(0xFF141A17);
  static const _darkText     = Color(0xFFF0F5F2);
  static const _lightText    = Color(0xFF111C17);
  static const _darkSubtext  = Color(0xFF8A9490);
  static const _lightSubtext = Color(0xFF5E6E68);

  @override
  Widget build(BuildContext context) {
    final isDark     = Provider.of<ThemeProvider>(context).isDarkMode;
    final locale     = Localizations.localeOf(context);
    final isSw       = locale.languageCode == 'sw';
    final primary    = isDark ? _darkPrimary  : _lightPrimary;
    final bg         = isDark ? _darkBg       : _lightBg;
    final surface    = isDark ? _darkSurface  : Colors.white;
    final textCol    = isDark ? _darkText     : _lightText;
    final subCol     = isDark ? _darkSubtext  : _lightSubtext;
    final shadow     = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.06);

    final activeTenants = tenants.where((t) => t.status == 'Active').length;
    final totalRent = tenants.fold(0.0, (s, t) => s + t.rentAmount);

    if (tenants.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.people_outline, size: 48, color: primary)),
          const SizedBox(height: 20),
          Text(
            context.tr('Hakuna Wapangaji', en: 'No Tenants Yet'),
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700, color: textCol),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Bonyeza + kuongeza mpangaji', en: 'Tap + to add a tenant'),
            style: GoogleFonts.poppins(fontSize: 14, color: subCol),
          ),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 12, offset: const Offset(0, 5))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statChip('${tenants.length}', isSw ? 'Jumla' : 'Total',
                Icons.people_rounded, Colors.white),
            _vDivider(),
            _statChip('$activeTenants', isSw ? 'Wanaokaa' : 'Active',
                Icons.check_circle_rounded, const Color(0xFF86EFAC)),
            _vDivider(),
            _statChip('TZS ${NumberFormat('#,###').format(totalRent)}',
                isSw ? 'Kodi Jumla' : 'Total Rent',
                Icons.monetization_on_rounded, const Color(0xFFFCD34D)),
          ]),
        ),
        // Tenant list
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          physics: const BouncingScrollPhysics(),
          itemCount: tenants.length,
          itemBuilder: (ctx, i) => _tenantCard(
              tenants[i], i, isDark, surface, textCol, subCol, primary, shadow, ctx, isSw),
        )),
      ]),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2));

  Widget _statChip(String value, String label, IconData icon, Color iconColor) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 4),
          Text(value, style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]);

  Widget _tenantCard(TenantData tenant, int i, bool isDark, Color surface,
      Color textCol, Color subCol, Color primary, Color shadow,
      BuildContext ctx, bool isSw) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + i * 50),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) =>
          Transform.translate(offset: Offset(24 * (1 - v), 0),
              child: Opacity(opacity: v, child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: shadow, blurRadius: 10, offset: const Offset(0, 3))],
          border: isDark ? Border.all(color: const Color(0xFF26312D), width: 0.5) : null),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => CustomDialogs.showTenantDetails(ctx, tenant.name,
                tenant.phone, tenant.houseName, tenant.rentAmount,
                tenant.startDate, tenant.endDate, tenant.status),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                // Avatar
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(
                    tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tenant.name, style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15, color: textCol)),
                  const SizedBox(height: 2),
                  Text(tenant.houseName, style: GoogleFonts.poppins(
                      fontSize: 12, color: subCol)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'TZS ${NumberFormat('#,###').format(tenant.rentAmount)}/mo',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: primary, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tenant.status == 'Active'
                            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        tenant.status == 'Active'
                            ? (isSw ? 'Anakaa' : 'Active') : tenant.status,
                        style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: tenant.status == 'Active'
                              ? const Color(0xFF22C55E) : Colors.grey))),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.chevron_right_rounded, color: primary, size: 20)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
