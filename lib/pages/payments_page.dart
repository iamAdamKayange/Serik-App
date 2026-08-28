import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import '../providers/theme_provider.dart';
import '../model/payment_model.dart';

class PaymentsPage extends StatelessWidget {
  final List<PaymentData> payments;

  const PaymentsPage({super.key, required this.payments});

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
    final isDark    = Provider.of<ThemeProvider>(context).isDarkMode;
    final locale    = Localizations.localeOf(context);
    final isSw      = locale.languageCode == 'sw';
    final primary   = isDark ? _darkPrimary  : _lightPrimary;
    final bg        = isDark ? _darkBg       : _lightBg;
    final surface   = isDark ? _darkSurface  : Colors.white;
    final textCol   = isDark ? _darkText     : _lightText;
    final subCol    = isDark ? _darkSubtext  : _lightSubtext;
    final tabBg     = isDark ? const Color(0xFF1C2420) : const Color(0xFFEAEDEB);
    final shadow    = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.06);

    final pending = payments.where((p) => p.status == 'Pending').toList();
    final paid    = payments.where((p) => p.status == 'Paid').toList();

    final totalPaid    = paid.fold(0.0, (s, p) => s + p.amount);
    final totalPending = pending.fold(0.0, (s, p) => s + p.amount);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(children: [
          // Summary bar
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
              _summaryItem('TZS ${NumberFormat('#,###').format(totalPaid)}',
                  context.tr('Imelipwa', en: 'Collected'),
                  Icons.check_circle_rounded, const Color(0xFF86EFAC)),
              Container(width: 1, height: 44,
                  color: Colors.white.withValues(alpha: 0.2)),
              _summaryItem('TZS ${NumberFormat('#,###').format(totalPending)}',
                  context.tr('Inasubiri', en: 'Pending'),
                  Icons.schedule_rounded, const Color(0xFFFCD34D)),
            ]),
          ),
          const SizedBox(height: 14),
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                  color: tabBg, borderRadius: BorderRadius.circular(16)),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? _darkSubtext : _lightSubtext,
                indicator: BoxDecoration(
                    color: primary, borderRadius: BorderRadius.circular(16)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.schedule_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(context.tr('Yanalipwa', en: 'Pending'),
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    _badge(pending.length.toString()),
                  ])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(context.tr('Yaliyolipwa', en: 'Paid'),
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    _badge(paid.length.toString()),
                  ])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: TabBarView(children: [
            _paymentList(context, pending, isDark, surface, textCol, subCol, primary, shadow, isSw, false),
            _paymentList(context, paid,    isDark, surface, textCol, subCol, primary, shadow, isSw, true),
          ])),
        ]),
      ),
    );
  }

  Widget _badge(String count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10)),
    child: Text(count, style: GoogleFonts.poppins(
        fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)));

  Widget _summaryItem(String value, String label, IconData icon, Color iconColor) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(value, style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]);

  Widget _paymentList(BuildContext context, List<PaymentData> list, bool isDark, Color surface,
      Color textCol, Color subCol, Color primary, Color shadow,
      bool isSw, bool isPaid) {
    final statusColor = isPaid ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    final emptyIcon   = isDark ? const Color(0xFF2A3330) : const Color(0xFFE8EDEB);
    final emptyText   = isDark ? const Color(0xFF8A9490) : const Color(0xFF5E6E68);

    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(color: emptyIcon, shape: BoxShape.circle),
          child: Icon(Icons.receipt_long_outlined, size: 42, color: emptyText)),
        const SizedBox(height: 16),
        Text(
          context.tr('Hakuna malipo', en: 'No payments found'),
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: textCol),
        ),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final p = list[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 40),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) =>
              Transform.translate(offset: Offset(0, 20 * (1 - v)),
                  child: Opacity(opacity: v, child: child)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 2))],
              border: isDark ? Border.all(color: const Color(0xFF26312D), width: 0.5) : null),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(
                    isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    color: statusColor, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.tenantName, style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: textCol, fontSize: 15)),
                  Text(p.month, style: GoogleFonts.poppins(fontSize: 12, color: subCol)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('TZS ${NumberFormat('#,###').format(p.amount)}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: isPaid ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      isPaid 
                          ? context.tr('Imelipwa', en: 'Paid') 
                          : context.tr('Inasubiri', en: 'Pending'),
                      style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}
