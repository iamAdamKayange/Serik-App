import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../model/payment_model.dart';

class ReportsPage extends StatelessWidget {
  final List<PaymentData> payments;
  final int totalHouses;
  final int occupiedHouses;
  final int totalTenants;

  const ReportsPage({
    super.key,
    required this.payments,
    required this.totalHouses,
    required this.occupiedHouses,
    required this.totalTenants,
  });

  static const _darkPrimary   = Color(0xFF46D39A);
  static const _lightPrimary  = Color(0xFF0F8B61);
  static const _darkBg        = Color(0xFF0A0F0D);
  static const _lightBg       = Color(0xFFF4F6F5);
  static const _darkSurface   = Color(0xFF141A17);
  static const _darkText      = Color(0xFFF0F5F2);
  static const _lightText     = Color(0xFF111C17);
  static const _darkSubtext   = Color(0xFF8A9490);
  static const _lightSubtext  = Color(0xFF5E6E68);
  static const _darkBorder    = Color(0xFF26312D);

  @override
  Widget build(BuildContext context) {
    final isDark   = Provider.of<ThemeProvider>(context).isDarkMode;
    final locale   = Localizations.localeOf(context);
    final isSw     = locale.languageCode == 'sw';
    final primary  = isDark ? _darkPrimary  : _lightPrimary;
    final bg       = isDark ? _darkBg       : _lightBg;
    final surface  = isDark ? _darkSurface  : Colors.white;
    final textCol  = isDark ? _darkText     : _lightText;
    final subCol   = isDark ? _darkSubtext  : _lightSubtext;
    final shadow   = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.06);

    final paidCount    = payments.where((p) => p.status == 'Paid').length;
    final pendingCount = payments.where((p) => p.status == 'Pending').length;
    final totalAmount  = payments.where((p) => p.status == 'Paid')
        .fold(0.0, (s, p) => s + p.amount);
    final occupancyPct = totalHouses > 0
        ? ((occupiedHouses / totalHouses) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Total Income hero ──────────────────────────────────────────
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: Opacity(opacity: v, child: child)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.65)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.2 : 0.3),
                    blurRadius: 20, offset: const Offset(0, 8))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(isSw ? 'JUMLA YA MAPATO' : 'TOTAL INCOME',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Text('TZS ${NumberFormat('#,###').format(totalAmount)}',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    isSw
                        ? 'Kutoka kwa malipo ${payments.length} yaliyothibitishwa'
                        : 'From ${payments.length} confirmed payment${payments.length == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))),
                const SizedBox(height: 16),
                // Occupancy pill row
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _heroPill(Icons.home_work_rounded, '$occupancyPct%',
                      isSw ? 'Asilimia ya Makazi' : 'Occupancy Rate'),
                  const SizedBox(width: 12),
                  _heroPill(Icons.people_rounded, '$totalTenants',
                      isSw ? 'Wapangaji' : 'Tenants'),
                  const SizedBox(width: 12),
                  _heroPill(Icons.home_rounded, '$totalHouses',
                      isSw ? 'Nyumba' : 'Properties'),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Revenue trend chart ────────────────────────────────────────
          _card(isDark, surface, shadow, textCol, subCol,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardHeader(Icons.trending_up_rounded, isSw ? 'Mwelekeo wa Mapato' : 'Revenue Trend',
                  primary, textCol),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: LineChart(_lineData(isDark, primary, subCol))),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Payment status cards ───────────────────────────────────────
          Row(children: [
            Expanded(child: _miniCard(
              isDark, surface, shadow, textCol, subCol,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF22C55E),
              value: '$paidCount',
              label: isSw ? 'Malipo Yaliyolipwa' : 'Paid Payments')),
            const SizedBox(width: 12),
            Expanded(child: _miniCard(
              isDark, surface, shadow, textCol, subCol,
              icon: Icons.schedule_rounded,
              color: const Color(0xFFF59E0B),
              value: '$pendingCount',
              label: isSw ? 'Malipo Yanasubiri' : 'Pending Payments')),
          ]),
          const SizedBox(height: 16),

          // ── Payment distribution donut ─────────────────────────────────
          if (paidCount + pendingCount > 0) ...[
            _card(isDark, surface, shadow, textCol, subCol,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _cardHeader(Icons.donut_large_rounded,
                    isSw ? 'Usambazaji wa Malipo' : 'Payment Distribution',
                    primary, textCol),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Row(children: [
                    Expanded(child: PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: paidCount.toDouble(),
                          color: const Color(0xFF22C55E),
                          radius: 30,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: pendingCount.toDouble(),
                          color: const Color(0xFFF59E0B),
                          radius: 30,
                          title: '',
                        ),
                      ],
                    ))),
                    const SizedBox(width: 16),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _legend(const Color(0xFF22C55E),
                          isSw ? 'Imelipwa ($paidCount)' : 'Paid ($paidCount)', subCol),
                      const SizedBox(height: 12),
                      _legend(const Color(0xFFF59E0B),
                          isSw ? 'Inasubiri ($pendingCount)' : 'Pending ($pendingCount)', subCol),
                    ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Property summary ───────────────────────────────────────────
          _card(isDark, surface, shadow, textCol, subCol,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardHeader(Icons.home_work_rounded,
                  isSw ? 'MUHTASARI WA NYUMBA' : 'PROPERTY SUMMARY',
                  primary, textCol),
              const SizedBox(height: 16),
              _row(isSw ? 'Jumla ya Nyumba'           : 'Total Houses',
                  '$totalHouses',    primary, textCol, subCol, isDark),
              _divider(isDark),
              _row(isSw ? 'Nyumba Zilizokodishwa'     : 'Occupied',
                  '$occupiedHouses', const Color(0xFF22C55E), textCol, subCol, isDark),
              _divider(isDark),
              _row(isSw ? 'Nyumba Wazi'               : 'Vacant',
                  '${totalHouses - occupiedHouses}',
                  const Color(0xFFF59E0B), textCol, subCol, isDark),
              _divider(isDark),
              _row(isSw ? 'Wapangaji'                 : 'Tenants',
                  '$totalTenants',   primary, textCol, subCol, isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    isSw
                        ? 'Asilimia ya makazi: $occupancyPct%'
                        : 'Occupancy rate: $occupancyPct%',
                    style: GoogleFonts.poppins(fontSize: 12, color: subCol))),
                ])),
            ]),
          ),
        ]),
      ),
    );
  }

  // Helper widgets
  Widget _heroPill(IconData icon, String value, String label) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label, style: GoogleFonts.poppins(
              color: Colors.white70, fontSize: 9.5)),
        ]));

  Widget _card(bool isDark, Color surface, Color shadow, Color textCol, Color subCol,
      {required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 4))],
          border: isDark ? Border.all(color: _darkBorder, width: 0.5) : null),
        child: child);

  Widget _cardHeader(IconData icon, String title, Color primary, Color textCol) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: primary)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, fontSize: 15, color: textCol))),
      ]);

  Widget _miniCard(bool isDark, Color surface, Color shadow, Color textCol, Color subCol,
      {required IconData icon, required Color color,
       required String value, required String label}) =>
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) =>
            Transform.scale(scale: v, child: Opacity(opacity: v, child: child)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: shadow, blurRadius: 10, offset: const Offset(0, 3))],
            border: isDark ? Border.all(color: _darkBorder, width: 0.5) : null),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w800, color: textCol)),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.poppins(
                color: subCol, fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ]),
        ));

  Widget _row(String label, String value, Color valColor,
      Color textCol, Color subCol, bool isDark) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.poppins(color: subCol, fontSize: 14)),
          Text(value, style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 16, color: valColor)),
        ]));

  Widget _divider(bool isDark) => Divider(height: 1,
      color: isDark ? _darkBorder : Colors.black.withValues(alpha: 0.06));

  Widget _legend(Color color, String label, Color subCol) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(color: subCol, fontSize: 12)),
      ]);

  LineChartData _lineData(bool isDark, Color primary, Color subCol) {
    final gridColor = isDark
        ? const Color(0xFF26312D)
        : const Color(0xFFE2E8E5);

    final spots = [
      const FlSpot(0, 500000), const FlSpot(1, 750000),
      const FlSpot(2, 620000), const FlSpot(3, 900000),
      const FlSpot(4, 830000), const FlSpot(5, 1200000),
      const FlSpot(6, 1100000),
    ];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

    return LineChartData(
      gridData: FlGridData(
        show: true, drawVerticalLine: false, horizontalInterval: 250000,
        getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1)),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28, interval: 1,
          getTitlesWidget: (v, _) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(months[v.toInt()],
                style: GoogleFonts.poppins(color: subCol, fontSize: 11))))),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 52, interval: 250000,
          getTitlesWidget: (v, _) => Text(
            '${(v / 1000000).toStringAsFixed(1)}M',
            style: GoogleFonts.poppins(color: subCol, fontSize: 10))))),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: gridColor)),
      minX: 0, maxX: 6, minY: 0, maxY: 1500000,
      lineBarsData: [LineChartBarData(
        spots: spots,
        isCurved: true,
        gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.6)]),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 4, color: primary,
            strokeWidth: 2, strokeColor: Colors.white)),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: isDark ? 0.2 : 0.15),
              primary.withValues(alpha: 0),
            ],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      )],
    );
  }
}
