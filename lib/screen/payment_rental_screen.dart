import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: const Text('Malipo ya Usajili'),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Kiasi cha Malipo',
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
                    'Ada ya Usajili wa Nyumba',
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
                    'Muhtasari wa Nyumba',
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
                          widget.houseData['location'] ?? 'Eneo',
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
              'Chagua Njia ya Malipo',
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
                          ? primaryColor.withOpacity(0.1)
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
                    'Namba ya Simu',
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
                    : const Text(
                        'Lipa Sasa',
                        style: TextStyle(
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ada hii ni ya kusajili nyumba yako. Baada ya malipo, nyumba yako itaonekana mara moja kwenye ramani.',
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
        CustomDialogs.showError(context, 'Tafadhali weka namba ya simu');
        return;
      }
      if (_phoneController.text.length < 10) {
        CustomDialogs.showError(context, 'Namba ya simu si sahihi');
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

      if (result['success'] == true) {
        _transactionId = result['transactionId'];
        _showPaymentInstructions(result['paymentInstruction']);
      } else {
        CustomDialogs.showError(
          context,
          result['message'] ?? 'Malipo yameshindikana',
        );
      }
    } catch (e) {
      CustomDialogs.showError(context, 'Hitilafu: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
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
            const Text('Maelekezo ya Malipo'),
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
                color: Colors.orange.withOpacity(0.1),
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
            child: const Text('Nimekamilisha Malipo'),
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
              'Inachakata malipo yako...',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tafadhali subiri',
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

      if (context.mounted) Navigator.pop(context);

      if (isPaid) {
        await _saveHouseToDatabase();
      } else {
        if (context.mounted) {
          CustomDialogs.showError(
            context,
            'Malipo bado hayajathibitishwa. Utapokea taarifa baada ya kuthibitishwa.',
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        CustomDialogs.showError(
          context,
          'Hitilafu wakati wa kuchakata malipo: $e',
        );
      }
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
          const SnackBar(
            content: Text(
              "Nyumba imesajiliwa kikamilifu! Asante kwa malipo yako.",
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
          'Nyumba imepokelewa lakini kuna hitilafu katika kuhifadhi. Tafadhali wasiliana na usaidizi.',
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
