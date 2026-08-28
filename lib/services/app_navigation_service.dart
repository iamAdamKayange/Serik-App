import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/pages/landlord_verification_page.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/pages/notification_screen.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';

class AppNavigationService {
  AppNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Map<String, dynamic>? _pendingNotificationPayload;

  static Future<void> openFromNotification(Map<String, dynamic> payload) async {
    final type = _extractNotificationType(payload);
    if (type == 'verification') {
      await _openVerificationTarget(payload);
      return;
    }
    if (type == 'payment' || type == 'maintenance' || type == 'alert') {
      await _openNotificationCenter(payload);
      return;
    }
    await openHouseFromNotification(payload);
  }

  static Future<void> openHouseFromNotification(
    Map<String, dynamic> payload,
  ) async {
    final houseId = _extractHouseId(payload);
    if (houseId == null || houseId.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNotificationPayload = payload;
      return;
    }

    final context = navigator.context;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      final loggedIn = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => LoginPage(redirectTo: 'details', spotId: houseId),
        ),
      );
      if (loggedIn == true) {
        await openHouseFromNotification(payload);
      } else {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Ingia kwanza kuona taarifa kamili za nyumba.'),
          ),
        );
      }
      return;
    }

    messenger?.showSnackBar(
      const SnackBar(content: Text('Inafungua nyumba...')),
    );

    final house = await ApiService.getHouseById(houseId);
    if (house == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Nyumba haikupatikana kwa sasa.')),
      );
      return;
    }

    final spot = RentalSpot.fromHouseData(HouseData.fromJson(house));
    unawaited(
      navigator.push(
        MaterialPageRoute(builder: (_) => RentalDetailScreen(spot: spot)),
      ),
    );
  }

  static Future<void> openHouseFromNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        await openFromNotification(decoded);
        return;
      }
    } catch (_) {
      await openFromNotification({'houseId': payload});
    }
  }

  static Future<void> flushPendingNotificationNavigation() async {
    final payload = _pendingNotificationPayload;
    if (payload == null) return;
    _pendingNotificationPayload = null;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await openFromNotification(payload);
  }

  static String? _extractHouseId(Map<String, dynamic> payload) {
    final direct = payload['houseId'] ?? payload['house_id'];
    if (direct != null) return direct.toString();

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['houseId'] ?? data['house_id'];
      if (nested != null) return nested.toString();
    }

    return null;
  }

  static String _extractNotificationType(Map<String, dynamic> payload) {
    final direct =
        payload['notificationType'] ?? payload['type'] ?? payload['category'];
    if (direct != null) return direct.toString().toLowerCase();

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['notificationType'] ??
          data['type'] ??
          data['category'];
      if (nested != null) return nested.toString().toLowerCase();
    }

    return 'house';
  }

  static Future<void> _openVerificationTarget(
    Map<String, dynamic> payload,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNotificationPayload = payload;
      return;
    }

    final context = navigator.context;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      final loggedIn = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginPage(redirectTo: 'verification'),
        ),
      );
      if (loggedIn != true) return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => const LandlordVerificationPage(),
      ),
    );
  }

  static Future<void> _openNotificationCenter(
    Map<String, dynamic> payload,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNotificationPayload = payload;
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );
  }
}
