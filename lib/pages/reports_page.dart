import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final paidCount = payments.where((p) => p.status == 'Paid').length;
    final pendingCount = payments.where((p) => p.status == 'Pending').length;
    final totalAmount = payments
        .where((p) => p.status == 'Paid')
        .fold(0.0, (sum, p) => sum + p.amount);

    // Dynamic colors based on dark mode
    final Color primaryColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF0D47A1);
    final Color cardShadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.08);
    final Color summaryBgColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color iconBgColor = isDark
        ? primaryColor.withOpacity(0.15)
        : primaryColor.withOpacity(0.1);

    // Gradient colors for total income card
    final List<Color> gradientColors = isDark
        ? [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)]
        : [const Color(0xFF0D47A1), const Color(0xFF1565C0)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total Income Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "JUMLA YA MAPATO",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "TZS ${NumberFormat('#,###').format(totalAmount)}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  "Malipo Yaliyolipwa",
                  paidCount.toString(),
                  Icons.check_circle,
                  const Color(0xFF2E7D32),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportCard(
                  "Malipo Yanalipwa",
                  pendingCount.toString(),
                  Icons.pending,
                  const Color(0xFFFF8F00),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: summaryBgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cardShadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: isDark
                  ? Border.all(color: Colors.grey[800]!, width: 0.5)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        size: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "MUHTASARI WA NYUMBA",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReportRow(
                  "Jumla ya Nyumba",
                  totalHouses.toString(),
                  isDark,
                  primaryColor,
                ),
                _buildReportRow(
                  "Nyumba Zilizokodishwa",
                  occupiedHouses.toString(),
                  isDark,
                  primaryColor,
                ),
                _buildReportRow(
                  "Nyumba Wazi",
                  (totalHouses - occupiedHouses).toString(),
                  isDark,
                  primaryColor,
                ),
                Divider(
                  height: 20,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                _buildReportRow(
                  "Wapangaji",
                  totalTenants.toString(),
                  isDark,
                  primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color labelColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.grey[800]!, width: 0.5)
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    bool isDark,
    Color primaryColor,
  ) {
    final Color labelColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color valueColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF0D47A1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: labelColor, fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
