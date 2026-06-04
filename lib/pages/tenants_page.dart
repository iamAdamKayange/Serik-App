import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../model/tenant_model.dart';
import '../widgets/custom_dialogs.dart';

class TenantsPage extends StatelessWidget {
  final List<TenantData> tenants;
  final VoidCallback onAddTenant;

  const TenantsPage({
    super.key,
    required this.tenants,
    required this.onAddTenant,
  });

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
    final Color primaryColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF0D47A1);
    final Color emptyIconColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    final Color emptyTextColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final Color shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.08);

    if (tenants.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: emptyIconColor),
              const SizedBox(height: 16),
              Text(
                "Hakuna wapangaji",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: emptyTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bonyeza + kuongeza mpangaji",
                style: GoogleFonts.poppins(color: subtextColor),
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
        itemCount: tenants.length,
        itemBuilder: (context, index) {
          final tenant = tenants[index];
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
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                child: Icon(Icons.person, color: primaryColor, size: 28),
              ),
              title: Text(
                tenant.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.houseName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: subtextColor,
                    ),
                  ),
                  Text(
                    "TZS ${NumberFormat('#,###').format(tenant.rentAmount)}/mwezi",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.chevron_right, color: primaryColor),
              ),
              onTap: () {
                CustomDialogs.showTenantDetails(
                  context,
                  tenant.name,
                  tenant.phone,
                  tenant.houseName,
                  tenant.rentAmount,
                  tenant.startDate,
                  tenant.endDate,
                  tenant.status,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
