import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:serik/pages/home_page.dart';
import 'package:serik/pages/rental_home_page.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/screen/onboarding_screen.dart';
import 'package:serik/services/app_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = context.read<ThemeProvider>();

    // Dynamic colors based on theme (though splash screen stays green for brand identity)
    final primaryGreen = themeProvider.isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final secondaryGreen = themeProvider.isDarkMode
        ? const Color(0xFF81C784)
        : const Color(0xFF4CAF50);
    final deepGreen = themeProvider.isDarkMode
        ? const Color(0xFF1B5E20)
        : const Color(0xFF1B5E20);

    // Animation controller kwa fade in/out ya logo
    final logoAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final logoScaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(
          parent: logoAnimationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    final fadeInAnimation = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: logoAnimationController, curve: Curves.easeOut),
      ),
    );

    // Animation controller kwa fade out kabla ya navigation
    final fadeOutController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    final fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: fadeOutController, curve: Curves.easeOut),
    );

    useEffect(() {
      // Baada ya 2 seconds, anza fade out
      Future.delayed(const Duration(seconds: 2), () {
        fadeOutController.forward().then((_) async {
          final prefs = await SharedPreferences.getInstance();
          final hasSeenOnboarding =
              prefs.getBool(OnboardingScreen.onboardingSeenKey) ?? false;
          
          if (!context.mounted) return;
          
          // Check authentication status and role
          final authProvider = context.read<AuthProvider>();
          
          if (!authProvider.isLoggedIn) {
            // If not logged in, go to onboarding or home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => hasSeenOnboarding
                    ? const HomePage()
                    : const OnboardingScreen(),
              ),
            );
          } else {
            // If logged in, redirect based on role
            if (authProvider.isLandlord) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RentalHomePage()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          }
          
          unawaited(AppNavigationService.flushPendingNotificationNavigation());
        });
      });
      return null;
    }, []);

    return Scaffold(
      body: AnimatedBuilder(
        animation: fadeOutAnimation,
        builder: (context, child) {
          return Opacity(opacity: fadeOutAnimation.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGreen, secondaryGreen, deepGreen],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                FadeTransition(
                  opacity: fadeInAnimation,
                  child: ScaleTransition(
                    scale: logoScaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 30,
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // House Icon
                          Icon(
                            Icons.home_rounded,
                            size: 70,
                            color: primaryGreen,
                          ),
                          // Key Icon with animation
                          Positioned(
                            bottom: 20,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1000),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, -5 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: primaryGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.key_rounded,
                                        size: 24,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // App Name with Green Theme
                const Text(
                  'SERIK',
                  style: TextStyle(
                    fontSize: 42,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    shadows: [
                      Shadow(
                        blurRadius: 15,
                        color: Colors.black26,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Suluhisho la Nyumba Za Kukodisha',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Pata nyumba bora za kukodisha kwa bei nafuu katika eneo lako',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 50),

                // Loading Indicator with Green Color
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

                const SizedBox(height: 20),

                // Powered by text with animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Powered by SERIK',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
