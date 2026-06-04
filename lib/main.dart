import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/providers/theme_provider.dart';
import 'package:serkapp/screen/splash_screen.dart';
import 'package:serkapp/services/csv_location_service.dart';
import 'package:serkapp/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Loading location data...');
    await CsvLocationService.loadAllLocations();
    debugPrint('Location data loaded successfully!');
    CsvLocationService.printLoadedRegions();
  } catch (e) {
    debugPrint('Error loading location data: $e');
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
      debugShowCheckedModeBanner: false,
      title: 'SERIK App',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
