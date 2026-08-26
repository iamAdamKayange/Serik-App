import 'package:flutter/material.dart';
import 'package:serik/services/api_services.dart';

class PaymentService {
  // Chaguzi za malipo
  static const List<Map<String, dynamic>> paymentOptions = [
    {
      'id': 'airtel_money',
      'name': 'Airtel Money',
      'icon': '📱',
      'color': '#FF0000',
    },
    {'id': 'm_pesa', 'name': 'M-Pesa', 'icon': '📱', 'color': '#4CAF50'},
    {'id': 'tigo_pesa', 'name': 'Tigo Pesa', 'icon': '📱', 'color': '#2196F3'},
    {'id': 'halopesa', 'name': 'HaloPesa', 'icon': '📱', 'color': '#FF9800'},
    {'id': 'card', 'name': 'Card Payment', 'icon': '💳', 'color': '#9C27B0'},
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': '🏦',
      'color': '#607D8B',
    },
  ];

  static const double registrationFee = 25000.0; // TZS 25,000

  // Store pending transaction status in memory (for demo purposes)
  static final Map<String, Map<String, dynamic>> _pendingTransactions = {};

  /// Initiate payment - simulates calling payment API
  static Future<Map<String, dynamic>> initiatePayment({
    required String userId,
    required String phoneNumber,
    required String paymentMethod,
    required double amount,
    required Map<String, dynamic> houseData,
    required List<String> imageUrls,
  }) async {
    try {
      debugPrint('💰 Initiating payment for user: $userId');
      debugPrint('📱 Payment method: $paymentMethod');
      debugPrint('💵 Amount: $amount');

      // Generate unique transaction ID
      final transactionId =
          'TXN_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, userId.length > 8 ? 8 : userId.length)}';

      // Save to memory (you can replace with shared_preferences or backend call)
      _pendingTransactions[transactionId] = {
        'transactionId': transactionId,
        'userId': userId,
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'houseData': houseData,
        'imageUrls': imageUrls,
        'status': 'pending',
        'createdAt': DateTime.now(),
      };

      // Simulate calling external payment API (replace with real integration)
      final paymentResponse = await _callPaymentAPI(
        transactionId: transactionId,
        phoneNumber: phoneNumber,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      if (paymentResponse['success']) {
        return {
          'success': true,
          'transactionId': transactionId,
          'message': 'Payment initiated successfully',
          'paymentInstruction': _getPaymentInstruction(
            paymentMethod,
            amount,
            transactionId,
          ),
        };
      } else {
        _pendingTransactions[transactionId]?['status'] = 'failed';
        return {
          'success': false,
          'message': paymentResponse['message'] ?? 'Payment initiation failed',
        };
      }
    } catch (e) {
      debugPrint('❌ Payment initiation error: $e');
      return {'success': false, 'message': 'Payment failed: $e'};
    }
  }

  /// Call external payment API (mock implementation)
  static Future<Map<String, dynamic>> _callPaymentAPI({
    required String transactionId,
    required String phoneNumber,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo, always return success
      // In production, replace with actual HTTP call to M-Pesa/Airtel API
      return {'success': true, 'message': 'Payment API call successful'};
    } catch (e) {
      return {'success': false, 'message': 'Payment API error: $e'};
    }
  }

  /// Verify payment status - polls external provider and saves house if successful
  static Future<bool> verifyPayment({required String transactionId}) async {
    try {
      debugPrint('🔍 Verifying payment for transaction: $transactionId');

      final transaction = _pendingTransactions[transactionId];
      if (transaction == null) {
        debugPrint('❌ Transaction not found: $transactionId');
        return false;
      }

      // If already completed, return true
      if (transaction['status'] == 'completed') {
        return true;
      }

      // If failed, return false
      if (transaction['status'] == 'failed') {
        return false;
      }

      // Check with payment provider (mock: after 5 seconds, assume success)
      final paymentStatus = await _checkPaymentStatusWithProvider(
        transactionId,
      );

      if (paymentStatus['status'] == 'completed') {
        // Update status in memory
        _pendingTransactions[transactionId]?['status'] = 'completed';

        // Prepare house data with image URLs and default videoUrls
        final Map<String, dynamic> finalHouseData = Map.from(
          transaction['houseData'],
        );
        finalHouseData['imageUrls'] = transaction['imageUrls'];
        if (!finalHouseData.containsKey('videoUrls')) {
          finalHouseData['videoUrls'] = [];
        }
        finalHouseData['status'] = 'Inapatikana';

        debugPrint('📡 Saving house to backend after payment...');
        final savedHouse = await ApiService.createHouse(finalHouseData);

        if (savedHouse != null) {
          debugPrint('✅ House saved successfully after payment');
          return true;
        } else {
          debugPrint('❌ Failed to save house after payment');
          return false;
        }
      } else if (paymentStatus['status'] == 'failed') {
        _pendingTransactions[transactionId]?['status'] = 'failed';
        return false;
      }

      // Still pending
      return false;
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      return false;
    }
  }

  /// Check payment status with payment provider (mock implementation)
  static Future<Map<String, dynamic>> _checkPaymentStatusWithProvider(
    String transactionId,
  ) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // In demo: after 8 seconds from creation, mark as completed
      final transaction = _pendingTransactions[transactionId];
      if (transaction != null) {
        final createdAt = transaction['createdAt'] as DateTime;
        final age = DateTime.now().difference(createdAt).inSeconds;
        if (age >= 8) {
          return {'status': 'completed'};
        }
      }
      return {'status': 'pending'};
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return {'status': 'pending'};
    }
  }

  /// Get payment instructions for user
  static String _getPaymentInstruction(
    String method,
    double amount,
    String transactionId,
  ) {
    switch (method) {
      case 'm_pesa':
        return '🔹 Tuma TZS ${amount.toStringAsFixed(0)} kwa namba 123456 ukitumia M-Pesa.\n'
            '🔹 Wewe Transaction ID: $transactionId kama kumbukumbu.\n'
            '🔹 Baada ya kutuma, bonyeza "Nimekamilisha Malipo".';
      case 'airtel_money':
        return '🔹 Tuma TZS ${amount.toStringAsFixed(0)} kwa namba 123456 ukitumia Airtel Money.\n'
            '🔹 Wewe Transaction ID: $transactionId kama kumbukumbu.\n'
            '🔹 Baada ya kutuma, bonyeza "Nimekamilisha Malipo".';
      case 'tigo_pesa':
        return '🔹 Tuma TZS ${amount.toStringAsFixed(0)} kwa namba 123456 ukitumia Tigo Pesa.\n'
            '🔹 Wewe Transaction ID: $transactionId kama kumbukumbu.\n'
            '🔹 Baada ya kutuma, bonyeza "Nimekamilisha Malipo".';
      case 'halopesa':
        return '🔹 Tuma TZS ${amount.toStringAsFixed(0)} kwa namba 123456 ukitumia HaloPesa.\n'
            '🔹 Wewe Transaction ID: $transactionId kama kumbukumbu.\n'
            '🔹 Baada ya kutuma, bonyeza "Nimekamilisha Malipo".';
      case 'card':
        return '🔹 Utawasilishwa kwenye ukurasa wa malipo ya kadi.\n'
            '🔹 Kamilisha malipo yako kwa kuingiza taarifa za kadi.\n'
            '🔹 Transaction ID: $transactionId';
      case 'bank_transfer':
        return '🔹 Tuma TZS ${amount.toStringAsFixed(0)} kwenye akaunti yetu ya benki:\n'
            '   Benki: CRDB Bank\n'
            '   A/C No: 1234567890\n'
            '   A/C Name: SERIK App\n'
            '🔹 Wewe Transaction ID: $transactionId kama kumbukumbu.\n'
            '🔹 Baada ya kutuma, bonyeza "Nimekamilisha Malipo".';
      default:
        return 'Malipo yako yanachakatwa. Transaction ID: $transactionId';
    }
  }

  // Optional helper methods (can be removed if not needed)
  static Future<bool> retryPayment(String transactionId) async {
    final transaction = _pendingTransactions[transactionId];
    if (transaction == null) return false;
    transaction['status'] = 'pending';
    return true;
  }

  static Future<bool> cancelTransaction(String transactionId) async {
    _pendingTransactions[transactionId]?['status'] = 'cancelled';
    return true;
  }

  static Future<Map<String, dynamic>?> getPendingTransaction(
    String transactionId,
  ) async {
    return _pendingTransactions[transactionId];
  }

  static Future<List<Map<String, dynamic>>> getUserPendingTransactions(
    String userId,
  ) async {
    return _pendingTransactions.values
        .where((t) => t['userId'] == userId && t['status'] == 'pending')
        .toList();
  }
}
