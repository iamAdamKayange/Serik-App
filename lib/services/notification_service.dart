import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:serkapp/firebase_options.dart';
import 'package:serkapp/services/app_navigation_service.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const AndroidNotificationChannel _newHousesChannel =
    AndroidNotificationChannel(
      'new_houses',
      'Nyumba mpya',
      description: 'Arifa za nyumba mpya zinazoongezwa SERIK',
      importance: Importance.high,
    );
const AndroidNotificationChannel _dailyReminderChannel =
    AndroidNotificationChannel(
      'daily_reminders',
      'Daily reminders',
      description: 'SERIK daily reminders',
      importance: Importance.defaultImportance,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 4801;
  static const String _installCutoffKey = 'notification_install_cutoff_at';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(
          AppNavigationService.openHouseFromNotificationPayload(
            response.payload,
          ),
        );
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_newHousesChannel);
    await androidPlugin?.createNotificationChannel(_dailyReminderChannel);
    await androidPlugin?.requestNotificationsPermission();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await scheduleDailyReminder();
    unawaited(_syncToken());

    messaging.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token: token));
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(AppNavigationService.openHouseFromNotification(message.data));
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(
        AppNavigationService.openHouseFromNotification(initialMessage.data),
      );
    }
  }

  Future<String?> getDeviceToken() async {
    return syncDeviceToken();
  }

  Future<void> scheduleDailyReminder() async {
    await _localNotifications.periodicallyShow(
      id: _dailyReminderId,
      title: 'SERIK',
      body: 'Fungua SERIK kuona nyumba mpya na fursa zilizo karibu nawe.',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily reminders',
          channelDescription: 'SERIK daily reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '{"type":"daily_reminder"}',
    );
  }

  Future<String?> syncDeviceToken({String? userId}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return null;
      await _registerToken(token: token, userId: userId);
      return token;
    } catch (e) {
      debugPrint('FCM token read failed: $e');
      return null;
    }
  }

  Future<void> _syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token: token);
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'SERIK';
    final body = notification?.body ?? message.data['body'] ?? '';

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'new_houses',
          'Nyumba mpya',
          channelDescription: 'Arifa za nyumba mpya zinazoongezwa SERIK',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name.toLowerCase();
  }

  Future<void> _registerToken({required String token, String? userId}) async {
    await ApiService.registerDeviceToken(
      token: token,
      platform: _platformName,
      userId: userId,
      installCutoffAt: await _installCutoffAt(),
    );
  }

  Future<String> _installCutoffAt() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installCutoffKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final now = DateTime.now().toUtc().toIso8601String();
    await prefs.setString(_installCutoffKey, now);
    return now;
  }
}
