import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:serik/firebase_options.dart';
import 'package:serik/services/app_navigation_service.dart';
import 'package:serik/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
  'serik_general',
  'SERIK General',
  description: 'Arifa za kawaida za SERIK',
  importance: Importance.defaultImportance,
);
const AndroidNotificationChannel _newHousesChannel = AndroidNotificationChannel(
  'serik_houses',
  'Nyumba mpya',
  description: 'Arifa za nyumba mpya zinazoongezwa SERIK',
  importance: Importance.high,
);
const AndroidNotificationChannel _paymentChannel = AndroidNotificationChannel(
  'serik_payments',
  'Malipo',
  description: 'Arifa za malipo, kodi na kumbukumbu',
  importance: Importance.high,
);
const AndroidNotificationChannel _verificationChannel =
    AndroidNotificationChannel(
      'serik_verification',
      'Uthibitishaji',
      description: 'Arifa za uthibitishaji wa landlord',
      importance: Importance.high,
    );
const AndroidNotificationChannel _maintenanceChannel =
    AndroidNotificationChannel(
      'serik_maintenance',
      'Matengenezo',
      description: 'Arifa za matengenezo na maintenance',
      importance: Importance.high,
    );
const AndroidNotificationChannel _alertsChannel = AndroidNotificationChannel(
  'serik_alerts',
  'Smart alerts',
  description: 'Arifa za nyumba zinazolingana na filter zako',
  importance: Importance.high,
);
const AndroidNotificationChannel _dailyReminderChannel =
    AndroidNotificationChannel(
      'serik_daily',
      'Daily reminders',
      description: 'SERIK daily reminders',
      importance: Importance.defaultImportance,
    );

const String _actionOpen = 'serik_action_open';
const String _actionDismiss = 'serik_action_dismiss';
const String _actionVerifyNow = 'serik_action_verify_now';

const String _darwinCategoryGeneral = 'serik_general_actions';
const String _darwinCategoryHouses = 'serik_house_actions';
const String _darwinCategoryPayments = 'serik_payment_actions';
const String _darwinCategoryVerification = 'serik_verification_actions';
const String _darwinCategoryMaintenance = 'serik_maintenance_actions';
const String _darwinCategoryAlerts = 'serik_alert_actions';

final DarwinNotificationAction _darwinOpenAction =
    DarwinNotificationAction.plain(
      _actionOpen,
      'Open',
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.foreground,
      },
    );
final DarwinNotificationAction _darwinDismissAction =
    DarwinNotificationAction.plain(
      _actionDismiss,
      'Dismiss',
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.destructive,
      },
    );
final DarwinNotificationAction _darwinVerifyAction =
    DarwinNotificationAction.plain(
      _actionVerifyNow,
      'Verify now',
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.foreground,
      },
    );

final List<DarwinNotificationCategory> _darwinNotificationCategories =
    <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        _darwinCategoryGeneral,
        actions: <DarwinNotificationAction>[
          _darwinOpenAction,
          _darwinDismissAction,
        ],
      ),
      DarwinNotificationCategory(
        _darwinCategoryHouses,
        actions: <DarwinNotificationAction>[
          _darwinOpenAction,
          _darwinDismissAction,
        ],
      ),
      DarwinNotificationCategory(
        _darwinCategoryPayments,
        actions: <DarwinNotificationAction>[
          _darwinOpenAction,
          _darwinDismissAction,
        ],
      ),
      DarwinNotificationCategory(
        _darwinCategoryVerification,
        actions: <DarwinNotificationAction>[
          _darwinOpenAction,
          _darwinVerifyAction,
          _darwinDismissAction,
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.customDismissAction,
        },
      ),
      DarwinNotificationCategory(
        _darwinCategoryMaintenance,
        actions: <DarwinNotificationAction>[
          _darwinOpenAction,
          _darwinDismissAction,
        ],
      ),
      DarwinNotificationCategory(
        _darwinCategoryAlerts,
        actions: <DarwinNotificationAction>[
          _darwinOpenAction,
          _darwinDismissAction,
        ],
      ),
    ];

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

@pragma('vm:entry-point')
Future<void> notificationBackgroundResponseHandler(
  NotificationResponse response,
) async {
  if (response.actionId == _actionDismiss) {
    return;
  }
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
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: _darwinNotificationCategories,
    );
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(_handleNotificationResponse(response));
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundResponseHandler,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_generalChannel);
    await androidPlugin?.createNotificationChannel(_newHousesChannel);
    await androidPlugin?.createNotificationChannel(_paymentChannel);
    await androidPlugin?.createNotificationChannel(_verificationChannel);
    await androidPlugin?.createNotificationChannel(_maintenanceChannel);
    await androidPlugin?.createNotificationChannel(_alertsChannel);
    await androidPlugin?.createNotificationChannel(_dailyReminderChannel);
    await androidPlugin?.requestNotificationsPermission();

    // Clear notifications on fresh install
    await _clearNotificationsOnFreshInstall();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await scheduleDailyReminder();
    unawaited(_syncToken());

    messaging.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token: token));
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(AppNavigationService.openFromNotification(message.data));
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(AppNavigationService.openFromNotification(initialMessage.data));
    }
  }

  Future<void> _clearNotificationsOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    const clearedKey = 'notifications_cleared';
    final cleared = prefs.getBool(clearedKey);

    if (cleared != true) {
      // This is a fresh install or upgrade - clear all notifications
      await _localNotifications.cancelAll();
      await prefs.setBool(clearedKey, true);
      debugPrint('Cleared all notifications on fresh install');
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
          'serik_daily',
          'Daily reminders',
          channelDescription: 'SERIK daily reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
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
    final type = _notificationTypeFromData(message.data);

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: _notificationDetailsForType(type),
      payload: jsonEncode(message.data),
    );
  }

  String _notificationTypeFromData(Map<String, dynamic> data) {
    final raw =
        (data['notificationType'] ?? data['type'] ?? data['category'] ?? '')
            .toString()
            .toLowerCase();
    if (raw.contains('payment') ||
        raw.contains('rent') ||
        raw.contains('kodi')) {
      return 'payment';
    }
    if (raw.contains('verify') ||
        raw.contains('verification') ||
        raw.contains('uthibitishaji')) {
      return 'verification';
    }
    if (raw.contains('maint') ||
        raw.contains('repair') ||
        raw.contains('fix')) {
      return 'maintenance';
    }
    if (raw.contains('alert') || raw.contains('smart')) {
      return 'alert';
    }
    if (raw.contains('house') ||
        raw.contains('property') ||
        raw.contains('nyumba')) {
      return 'house';
    }
    return 'general';
  }

  AndroidNotificationChannel _channelForType(String type) {
    switch (type) {
      case 'payment':
        return _paymentChannel;
      case 'verification':
        return _verificationChannel;
      case 'maintenance':
        return _maintenanceChannel;
      case 'alert':
        return _alertsChannel;
      case 'house':
        return _newHousesChannel;
      default:
        return _generalChannel;
    }
  }

  NotificationDetails _notificationDetailsForType(String type) {
    final channel = _channelForType(type);
    final shouldVibrate = type != 'general';
    final actions = _androidActionsForType(type);
    final categoryIdentifier = _darwinCategoryForType(type);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: shouldVibrate,
        vibrationPattern: shouldVibrate
            ? Int64List.fromList([0, 350, 200, 350])
            : null,
        actions: actions,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        categoryIdentifier: categoryIdentifier,
      ),
    );
  }

  List<AndroidNotificationAction>? _androidActionsForType(String type) {
    final normalized = type.toLowerCase();
    final openAction = AndroidNotificationAction(
      _actionOpen,
      'Open',
      showsUserInterface: true,
    );
    final dismissAction = AndroidNotificationAction(
      _actionDismiss,
      'Dismiss',
      showsUserInterface: false,
      semanticAction: SemanticAction.delete,
    );
    if (normalized == 'verification') {
      return <AndroidNotificationAction>[
        openAction,
        AndroidNotificationAction(
          _actionVerifyNow,
          'Verify now',
          showsUserInterface: true,
        ),
        dismissAction,
      ];
    }
    return <AndroidNotificationAction>[openAction, dismissAction];
  }

  String _darwinCategoryForType(String type) {
    switch (type) {
      case 'payment':
        return _darwinCategoryPayments;
      case 'verification':
        return _darwinCategoryVerification;
      case 'maintenance':
        return _darwinCategoryMaintenance;
      case 'alert':
        return _darwinCategoryAlerts;
      case 'house':
        return _darwinCategoryHouses;
      default:
        return _darwinCategoryGeneral;
    }
  }

  static Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == _actionDismiss) {
      final notificationId = response.id;
      if (notificationId != null) {
        await _localNotifications.cancel(id: notificationId);
      }
      return;
    }

    if (actionId == _actionVerifyNow) {
      await AppNavigationService.openFromNotification(
        _decodePayload(payload, fallbackType: 'verification'),
      );
      return;
    }

    if (payload == null || payload.isEmpty) {
      return;
    }

    await AppNavigationService.openHouseFromNotificationPayload(payload);
  }

  static Map<String, dynamic> _decodePayload(
    String? payload, {
    required String fallbackType,
  }) {
    if (payload == null || payload.isEmpty) {
      return <String, dynamic>{'type': fallbackType};
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Keep fallback payload below.
    }
    return <String, dynamic>{'type': fallbackType, 'rawPayload': payload};
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

    // Check if this is a fresh install by checking a separate key
    const firstInstallKey = 'app_first_install_time';
    final firstInstall = prefs.getString(firstInstallKey);

    if (firstInstall == null) {
      // This is a fresh install
      final now = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(firstInstallKey, now);
      await prefs.setString(_installCutoffKey, now);
      return now;
    }

    // If installCutoffAt exists, use it. Otherwise, use first install time
    if (existing != null && existing.isNotEmpty) return existing;

    await prefs.setString(_installCutoffKey, firstInstall);
    return firstInstall;
  }
}
