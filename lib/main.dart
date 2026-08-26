import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:serik/firebase_options.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:provider/provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/screen/splash_screen.dart';
import 'package:serik/services/app_navigation_service.dart';
import 'package:serik/services/csv_location_service.dart';
import 'package:serik/services/notification_service.dart';
import 'package:serik/services/network_status_service.dart';
import 'package:serik/services/realtime_service.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/theme/app_theme.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable secure network communication in release mode
  if (kReleaseMode) {
    // Additional security configurations for production
    debugPrint = (String? message, {int? wrapWidth}) {
      // Disable debug prints in production
    };
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Handle Firebase initialization error gracefully
  }

  try {
    await NotificationService.instance.initialize();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Notification service initialization error: $e');
  }

  try {
    debugPrint('Loading location data...');
    await CsvLocationService.loadAllLocations();
    debugPrint('Location data loaded successfully!');
    CsvLocationService.printLoadedRegions();
  } catch (e) {
    debugPrint('Error loading location data: $e');
    // Continue without location data if it fails
  }

  // Initialize services with error handling
  try {
    RealtimeService.instance.connect();
    debugPrint('Realtime service connected');
  } catch (e) {
    debugPrint('Realtime service connection error: $e');
  }

  try {
    NetworkStatusService.instance.start();
    debugPrint('Network status service started');
  } catch (e) {
    debugPrint('Network status service error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: AppNavigationService.navigatorKey,
      debugShowCheckedModeBanner: kDebugMode,
      title: AppLocalizations(themeProvider.locale).appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: themeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: NetworkStatusService.instance.isOnline,
          builder: (context, isOnline, _) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (!isOnline)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Unafanya kazi offline. Data ita-sync ukipata intaneti.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      home: const SplashScreen(),
    );
  }
}
