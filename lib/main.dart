import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/model/theme_model.dart';
import 'package:serkapp/screen/splash_screen.dart';
import 'package:serkapp/services/csv_location_service.dart';
import 'package:serkapp/theme/dark_mode.dart';
import 'package:serkapp/theme/light_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ongeza try-catch kwa error handling
  try {
    debugPrint('🟢 Loading location data...');
    await CsvLocationService.loadAllLocations();
    debugPrint('✅ Location data loaded successfully!');
    CsvLocationService.printLoadedRegions(); // Debug: show loaded regions
  } catch (e) {
    debugPrint('❌ Error loading location data: $e');
  }

  runApp(ChangeNotifierProvider(create: (_) => ThemeModel(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeModel>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: darkMode,
      themeMode: themeProvider.themeMode,
      title: 'Ramani Mwenye Nyumba',
      theme: lightMode,
      home: SplashScreen(),
    );
  }
}
