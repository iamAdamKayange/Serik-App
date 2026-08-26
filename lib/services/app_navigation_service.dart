import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';

class AppNavigationService {
  AppNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Map<String, dynamic>? _pendingHousePayload;

  static Future<void> openHouseFromNotification(
    Map<String, dynamic> payload,
  ) async {
    final houseId = _extractHouseId(payload);
    if (houseId == null || houseId.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingHousePayload = payload;
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
        await openHouseFromNotification(decoded);
        return;
      }
    } catch (_) {
      await openHouseFromNotification({'houseId': payload});
    }
  }

  static Future<void> flushPendingNotificationNavigation() async {
    final payload = _pendingHousePayload;
    if (payload == null) return;
    _pendingHousePayload = null;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await openHouseFromNotification(payload);
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
}
