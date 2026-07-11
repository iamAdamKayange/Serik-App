import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:serkapp/firebase_options.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/providers/theme_provider.dart';
import 'package:serkapp/screen/splash_screen.dart';
import 'package:serkapp/services/app_navigation_service.dart';
import 'package:serkapp/services/csv_location_service.dart';
import 'package:serkapp/services/notification_service.dart';
import 'package:serkapp/services/realtime_service.dart';
import 'package:serkapp/providers/auth_provider.dart';
import 'package:serkapp/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();

  try {
    debugPrint('Loading location data...');
    await CsvLocationService.loadAllLocations();
    debugPrint('Location data loaded successfully!');
    CsvLocationService.printLoadedRegions();
  } catch (e) {
    debugPrint('Error loading location data: $e');
  }

  RealtimeService.instance.connect();

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
      debugShowCheckedModeBanner: false,
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
      home: const SplashScreen(),
    );
  }
}
