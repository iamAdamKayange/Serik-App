import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../model/maintenance_model.dart';

class MaintenancePage extends StatelessWidget {
  final List<MaintenanceData> maintenanceRequests;

  const MaintenancePage({super.key, required this.maintenanceRequests});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // Dynamic colors
    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : Colors.grey[50]!;
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color emptyIconColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    final Color emptyTextColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final Color shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.08);

    if (maintenanceRequests.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handyman_outlined, size: 80, color: emptyIconColor),
              const SizedBox(height: 16),
              Text(
                "Hakuna maombi ya matengenezo",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: emptyTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: maintenanceRequests.length,
        itemBuilder: (context, index) {
          final req = maintenanceRequests[index];
          Color priorityColor = req.priority == 'High'
              ? const Color(0xFFD32F2F)
              : (req.priority == 'Medium'
                    ? const Color(0xFFFF8F00)
                    : const Color(0xFF2E7D32));

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.build, color: priorityColor, size: 24),
              ),
              title: Text(
                req.issue,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${req.houseName} - ${req.tenantName}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.status,
                      style: GoogleFonts.poppins(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req.priority,
                  style: GoogleFonts.poppins(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
