import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import '../providers/theme_provider.dart';
import '../model/maintenance_model.dart';

class MaintenancePage extends StatelessWidget {
  final List<MaintenanceData> maintenanceRequests;

  const MaintenancePage({super.key, required this.maintenanceRequests});

  static const _darkPrimary  = Color(0xFF46D39A);
  static const _lightPrimary = Color(0xFF00695C);
  static const _darkBg       = Color(0xFF0A0F0D);
  static const _lightBg      = Color(0xFFF4F6F5);
  static const _darkSurface  = Color(0xFF141A17);
  static const _darkText     = Color(0xFFF0F5F2);
  static const _lightText    = Color(0xFF111C17);
  static const _darkSubtext  = Color(0xFF8A9490);
  static const _lightSubtext = Color(0xFF5E6E68);

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<ThemeProvider>(context).isDarkMode;
    final locale  = Localizations.localeOf(context);
    final isSw    = locale.languageCode == 'sw';
    final primary = isDark ? _darkPrimary  : _lightPrimary;
    final bg      = isDark ? _darkBg       : _lightBg;
    final surface = isDark ? _darkSurface  : Colors.white;
    final textCol = isDark ? _darkText     : _lightText;
    final subCol  = isDark ? _darkSubtext  : _lightSubtext;
    final shadow  = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.06);

    final highPriority = maintenanceRequests.where((r) => r.priority == 'High').length;
    final pendingCount = maintenanceRequests
        .where((r) => r.status == 'Inasubiri' || r.status == 'Pending').length;

    if (maintenanceRequests.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.handyman_outlined, size: 48, color: primary)),
          const SizedBox(height: 20),
          Text(
            context.tr('Hakuna Maombi ya Matengenezo', en: 'No Maintenance Requests'),
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: textCol),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Maombi yote yataonekana hapa', en: 'All requests will appear here'),
              style: GoogleFonts.poppins(fontSize: 14, color: subCol)),
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
            _chip('${maintenanceRequests.length}', isSw ? 'Jumla' : 'Total',
                Icons.handyman_rounded, Colors.white),
            _vDiv(),
            _chip('$pendingCount', isSw ? 'Zinasubiri' : 'Pending',
                Icons.schedule_rounded, const Color(0xFFFCD34D)),
            _vDiv(),
            _chip('$highPriority', isSw ? 'Muhimu' : 'High Priority',
                Icons.warning_rounded, const Color(0xFFFCA5A5)),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          physics: const BouncingScrollPhysics(),
          itemCount: maintenanceRequests.length,
          itemBuilder: (_, i) => _card(
            maintenanceRequests[i], i, isDark, surface, textCol, subCol, shadow, isSw),
        )),
      ]),
    );
  }

  Widget _vDiv() => Container(width: 1, height: 40,
      color: Colors.white.withValues(alpha: 0.2));

  Widget _chip(String value, String label, IconData icon, Color iconColor) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 4),
          Text(value, style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]);

  Widget _card(MaintenanceData req, int index, bool isDark, Color surface,
      Color textCol, Color subCol, Color shadow, bool isSw) {
    Color priorityColor;
    switch (req.priority) {
      case 'High':   priorityColor = const Color(0xFFEF4444); break;
      case 'Medium': priorityColor = const Color(0xFFF59E0B); break;
      default:       priorityColor = const Color(0xFF22C55E);
    }

    Color statusColor;
    if (req.status == 'Inasubiri' || req.status == 'Pending') {
      statusColor = const Color(0xFFF59E0B);
    } else if (req.status == 'Inarudiwa' || req.status == 'In Progress') {
      statusColor = const Color(0xFF60A5FA);
    } else {
      statusColor = const Color(0xFF22C55E);
    }

    String statusLabel = isSw
        ? (req.status == 'Pending'
            ? 'Inasubiri'
            : req.status == 'In Progress'
                ? 'Inaendelea'
                : req.status == 'Completed'
                    ? 'Imekamilika'
                    : req.status)
        : req.status;

    String priorityLabel = isSw
        ? (req.priority == 'High'
            ? 'Juu'
            : req.priority == 'Medium'
                ? 'Wastani'
                : req.priority == 'Low'
                    ? 'Chini'
                    : req.priority)
        : req.priority;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 55),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(
                req.priority == 'High' ? Icons.error_rounded : Icons.build_rounded,
                color: priorityColor, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req.issue, style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 15, color: textCol),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${req.houseName} · ${req.tenantName}',
                  style: GoogleFonts.poppins(fontSize: 12, color: subCol)),
              const SizedBox(height: 8),
              Row(children: [
                _pill(statusLabel, statusColor),
                const SizedBox(width: 8),
                _pill(priorityLabel, priorityColor),
              ]),
            ])),
            if (req.assignedTo != null && req.assignedTo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Tooltip(
                  message: isSw
                      ? 'Imetumwa kwa: ${req.assignedTo}'
                      : 'Assigned: ${req.assignedTo}',
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C2420) : const Color(0xFFEAEDEB),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.person_rounded, size: 18, color: subCol)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: GoogleFonts.poppins(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)));
}
