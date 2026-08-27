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
            return Scaffold(
              body: _buildOfflineBanner(context, isOnline, child),
            );
          },
        );
      },
      home: const SplashScreen(),
    );
  }

  Widget _buildOfflineBanner(
    BuildContext context,
    bool isOnline,
    Widget? child,
  ) {
    if (isOnline) {
      return child ?? const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final appLocalizations = AppLocalizations(locale);

    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: isDark ? Colors.grey[900] : Colors.grey[800],
            elevation: 2,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: isDark ? Colors.orange[300] : Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appLocalizations.offline,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.orange[300] : Colors.orange)
                            ?.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appLocalizations.offlineSync,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
