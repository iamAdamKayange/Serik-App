import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/l10n/app_localization.dart';

class CustomDialogs {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B8A5A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        showCloseIcon: true,
        closeIconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        showCloseIcon: true,
        closeIconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  static void showProfileDialog(
    BuildContext context,
    int houseCount,
    VoidCallback onLogout, {
    bool isDarkMode = false,
  }) {
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color labelColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color primaryColor = const Color(0xFF0D47A1);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDarkMode
              ? BorderSide(color: Colors.grey[800]!, width: 0.5)
              : BorderSide.none,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_circle, size: 28, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('Profile Yako', en: 'Your Profile'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow(
              Icons.person_outline,
              context.tr('Jina', en: 'Name'),
              context.tr('Mpangishaji Pro', en: 'Landlord Pro'),
              isDarkMode: isDarkMode,
            ),
            _buildProfileRow(
              Icons.email_outlined,
              context.tr('Barua Pepe', en: 'Email'),
              "mpangishaji@serkapp.com",
              isDarkMode: isDarkMode,
            ),
            _buildProfileRow(
              Icons.phone_outlined,
              context.tr('Simu', en: 'Phone'),
              "+255 123 456 789",
              isDarkMode: isDarkMode,
            ),
            _buildProfileRow(
              Icons.home_work_outlined,
              context.tr('Nyumba Zako', en: 'Your Houses'),
              context.tr('$houseCount nyumba', en: '$houseCount houses'),
              isDarkMode: isDarkMode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('Funga', en: 'Close'),
              style: GoogleFonts.poppins(color: labelColor),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
            },
            icon: const Icon(Icons.logout, size: 18, color: Colors.white),
            label: Text(
              "Logout",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showTenantDetails(
    BuildContext context,
    String name,
    String phone,
    String houseName,
    double rentAmount,
    DateTime startDate,
    DateTime? endDate,
    String status, {
    bool isDarkMode = false,
  }) {
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color primaryColor = const Color(0xFF0D47A1);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDarkMode
              ? BorderSide(color: Colors.grey[800]!, width: 0.5)
              : BorderSide.none,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, size: 24, color: primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.phone,
              context.tr('Simu', en: 'Phone'),
              phone,
              isDarkMode: isDarkMode,
            ),
            _buildDetailRow(
              Icons.home,
              context.tr('Nyumba', en: 'House'),
              houseName,
              isDarkMode: isDarkMode,
            ),
            _buildDetailRow(
              Icons.attach_money,
              context.tr('Kodi', en: 'Rent'),
              "TZS ${NumberFormat('#,###').format(rentAmount)}",
              isDarkMode: isDarkMode,
            ),
            _buildDetailRow(
              Icons.calendar_today,
              context.tr('Kuanzia', en: 'From'),
              DateFormat('dd/MM/yyyy').format(startDate),
              isDarkMode: isDarkMode,
            ),
            if (endDate != null)
              _buildDetailRow(
                Icons.event,
                context.tr('Mwisho', en: 'End'),
                DateFormat('dd/MM/yyyy').format(endDate),
                isDarkMode: isDarkMode,
              ),
            _buildDetailRow(
              Icons.badge,
              context.tr('Hali', en: 'Status'),
              status,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('Funga', en: 'Close'),
              style: GoogleFonts.poppins(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildProfileRow(
    IconData icon,
    String label,
    String value, {
    bool isDarkMode = false,
  }) {
    final Color labelColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: labelColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isDarkMode = false,
  }) {
    final Color labelColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color iconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: labelColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
