import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serkapp/screen/onboarding_screen.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Animation controller kwa fade in/out
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final fadeInAnimation = useMemoized(
      () => Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
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
        fadeOutController.forward().then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0), // Blue Dark
                Color(0xFF42A5F5), // Blue Light
                Color(0xFF1565C0), // Blue Dark
              ],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: fadeInAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated House Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 25,
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Icon(
                          Icons.house_rounded,
                          size: 60,
                          color: Color(0xFF1565C0),
                        ),
                        Positioned(
                          bottom: 15,
                          child: Icon(
                            Icons.key_rounded,
                            size: 20,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'SERIK APP',
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Suluhisho la Nyumba Za Kukodisha',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Pata nyumba bora za kukodisha kwa bei nafuu katika eneo lako',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
