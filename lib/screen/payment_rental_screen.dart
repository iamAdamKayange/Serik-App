import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/pages/admin_map_page.dart';
import 'package:serkapp/services/payment_service.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/providers/theme_provider.dart';
import 'package:serkapp/providers/auth_provider.dart';
import '../widgets/custom_dialogs.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> houseData;
  final List<dynamic> images; // XFile list (for retry if needed)
  final List<String> imageUrls; // Already uploaded image URLs

  const PaymentPage({
    super.key,
    required this.houseData,
    required this.images,
    required this.imageUrls,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'm_pesa';
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  String? _transactionId;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : Colors.grey[50]!;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(context.tr('Malipo ya Usajili', en: 'Registration Payment')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    context.tr('Kiasi cha Malipo', en: 'Payment Amount'),
                    style: TextStyle(fontSize: 14, color: subtextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TZS ${PaymentService.registrationFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Ada ya Usajili wa Nyumba',
                      en: 'House Registration Fee',
                    ),
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Property Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Muhtasari wa Nyumba', en: 'House Summary'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.home, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.houseData['name'] ?? 'Jina la Nyumba',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.houseData['location'] ??
                              context.tr('Eneo', en: 'Location'),
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method Selection
            Text(
              context.tr('Chagua Njia ya Malipo', en: 'Choose Payment Method'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: PaymentService.paymentOptions.length,
              itemBuilder: (context, index) {
                final option = PaymentService.paymentOptions[index];
                final isSelected = _selectedPaymentMethod == option['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = option['id'] as String;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.1)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          option['icon'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? primaryColor : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Phone Number Field (for mobile payments)
            if (_selectedPaymentMethod != 'card' &&
                _selectedPaymentMethod != 'bank_transfer')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Namba ya Simu', en: 'Phone Number'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: '0712345678',
                      hintStyle: TextStyle(color: subtextColor),
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        context.tr('Lipa Sasa', en: 'Pay Now'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Ada hii ni ya kusajili nyumba yako. Baada ya malipo, nyumba yako itaonekana mara moja kwenye ramani.',
                        en: 'This fee registers your house. After payment, your house will appear on the map immediately.',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validate phone number for mobile payments
    if (_selectedPaymentMethod != 'card' &&
        _selectedPaymentMethod != 'bank_transfer') {
      if (_phoneController.text.isEmpty) {
        CustomDialogs.showError(
          context,
          context.tr(
            'Tafadhali weka namba ya simu',
            en: 'Please enter a phone number',
          ),
        );
        return;
      }
      if (_phoneController.text.length < 10) {
        CustomDialogs.showError(
          context,
          context.tr('Namba ya simu si sahihi', en: 'Phone number is invalid'),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await PaymentService.initiatePayment(
        userId: authProvider.userId!,
        phoneNumber: _phoneController.text,
        paymentMethod: _selectedPaymentMethod,
        amount: PaymentService.registrationFee,
        houseData: widget.houseData,
        imageUrls: widget.imageUrls,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        _transactionId = result['transactionId'];
        _showPaymentInstructions(result['paymentInstruction']);
      } else {
        CustomDialogs.showError(
          context,
          result['message'] ??
              context.tr('Malipo yameshindikana', en: 'Payment failed'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomDialogs.showError(
        context,
        '${context.tr('Hitilafu', en: 'Error')}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPaymentInstructions(String instructions) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.payment, color: primaryColor),
            const SizedBox(width: 8),
            Text(context.tr('Maelekezo ya Malipo', en: 'Payment Instructions')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instructions, style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Malipo yatahitaji kuthibitishwa ndani ya dakika 30. '
                      'Utapokea taarifa baada ya uthibitisho.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus();
            },
            child: Text(
              context.tr(
                'Nimekamilisha Malipo',
                en: 'I Have Completed Payment',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _isProcessing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              context.tr(
                'Inachakata malipo yako...',
                en: 'Processing your payment...',
              ),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Tafadhali subiri', en: 'Please wait'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      bool isPaid = false;
      int attempts = 0;
      const maxAttempts = 10;

      while (!isPaid && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 3));
        isPaid = await PaymentService.verifyPayment(
          transactionId: _transactionId!,
        );
        attempts++;
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (isPaid) {
        await _saveHouseToDatabase();
      } else {
        if (!mounted) return;
        CustomDialogs.showError(
          context,
          context.tr(
            'Malipo bado hayajathibitishwa. Utapokea taarifa baada ya kuthibitishwa.',
            en: 'Payment has not been confirmed yet. You will receive a notification after confirmation.',
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      CustomDialogs.showError(
        context,
        '${context.tr('Hitilafu wakati wa kuchakata malipo', en: 'Error while processing payment')}: $e',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveHouseToDatabase() async {
    try {
      final Map<String, dynamic> finalHouseData = Map.from(widget.houseData);
      finalHouseData['status'] = 'Inapatikana';
      finalHouseData['imageUrls'] = widget.imageUrls;
      // Ensure videoUrls are passed if they exist in houseData
      if (!finalHouseData.containsKey('videoUrls')) {
        finalHouseData['videoUrls'] = [];
      }

      debugPrint('📡 Saving house to Node.js backend after payment...');
      final result = await ApiService.createHouse(finalHouseData);

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Nyumba imesajiliwa kikamilifu! Asante kwa malipo yako.',
                en: 'House registered successfully! Thank you for your payment.',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  const AdminMapPage(), // newlyAddedHouse can be fetched later
            ),
            (route) => false,
          );
        }
      } else {
        throw Exception("Failed to save house");
      }
    } catch (e) {
      debugPrint('❌ Error saving house: $e');
      if (mounted) {
        CustomDialogs.showError(
          context,
          context.tr(
            'Nyumba imepokelewa lakini kuna hitilafu katika kuhifadhi. Tafadhali wasiliana na usaidizi.',
            en: 'The house was received but there was an error saving it. Please contact support.',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
