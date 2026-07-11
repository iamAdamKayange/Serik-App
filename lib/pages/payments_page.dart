import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../model/payment_model.dart';

class PaymentsPage extends StatelessWidget {
  final List<PaymentData> payments;

  const PaymentsPage({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final pendingPayments = payments
        .where((p) => p.status == 'Pending')
        .toList();
    final paidPayments = payments.where((p) => p.status == 'Paid').toList();

    // Dynamic colors
    final Color primaryColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF0D47A1);
    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : Colors.grey[50]!;
    final Color tabBgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color emptyIconColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tabBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                tabs: const [
                  Tab(text: "Yanalipwa", icon: Icon(Icons.pending)),
                  Tab(text: "Yaliyolipwa", icon: Icon(Icons.check_circle)),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPaymentList(
                    pendingPayments,
                    isDark,
                    textColor,
                    subtextColor,
                    emptyIconColor,
                    primaryColor,
                  ),
                  _buildPaymentList(
                    paidPayments,
                    isDark,
                    textColor,
                    subtextColor,
                    emptyIconColor,
                    primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(
    List<PaymentData> paymentsList,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color emptyIconColor,
    Color primaryColor,
  ) {
    if (paymentsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 80, color: emptyIconColor),
            const SizedBox(height: 16),
            Text(
              "Hakuna malipo",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentsList.length,
      itemBuilder: (context, index) {
        final payment = paymentsList[index];
        final bool isPaid = payment.status == 'Paid';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.withValues(alpha: isDark ? 0.2 : 0.1)
                    : Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            title: Text(
              payment.tenantName,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
            subtitle: Text(
              payment.month,
              style: TextStyle(color: subtextColor),
            ),
            trailing: Text(
              "TZS ${NumberFormat('#,###').format(payment.amount)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPaid ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
        );
      },
    );
  }
}
