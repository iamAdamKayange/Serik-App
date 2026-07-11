import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/pages/home_page.dart';
import 'package:serkapp/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends HookConsumerWidget {
  static const onboardingSeenKey = 'has_seen_onboarding';

  const OnboardingScreen({super.key});

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingSeenKey, true);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final themeProvider = context.read<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    final onboardingData = [
      {
        'title': context.tr('Pata Nyumba Bora', en: 'Find Better Housing'),
        'description': context.tr(
          'Tafuta nyumba za kupanga katika maeneo mbalimbali kwa bei nafuu na mazingira salama. Tunakusaidia kupata makazi yako bora.',
          en: 'Search rental homes in different areas with fair prices and safer surroundings. We help you find the right place to live.',
        ),
        'icon': Icons.search_rounded,
        'color': const Color(0xFF2E7D32),
        'image': '🏠',
        'gradientLight': [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
        'gradientDark': [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)],
      },
      {
        'title': context.tr(
          'Wasiliana Moja kwa Moja',
          en: 'Contact Directly',
        ),
        'description': context.tr(
          'Wasiliana na wakodisha moja kwa moja bila mwingiliano wa mtu wa tatu. Pata majibu ya haraka na maelezo kamili ya nyumba.',
          en: 'Talk to landlords directly without a third party. Get quick answers and complete house information.',
        ),
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF4CAF50),
        'image': '💬',
        'gradientLight': [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
        'gradientDark': [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
      },
      {
        'title': context.tr(
          'Nyumba Salama na Uhakika',
          en: 'Safe and Trusted Homes',
        ),
        'description': context.tr(
          'Pata nyumba zenye usalama wa kutosha, hati rasmi za kukodisha, na mazingira rafiki kwa maisha yako. Usalama wako ni kipaumbele chetu.',
          en: 'Find homes with reliable safety, clear rental information and friendly surroundings. Your safety comes first.',
        ),
        'icon': Icons.security_rounded,
        'color': const Color(0xFF66BB6A),
        'image': '🔒',
        'gradientLight': [const Color(0xFF43A047), const Color(0xFF2E7D32)],
        'gradientDark': [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)],
      },
    ];

    // Dynamic colors based on theme
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final indicatorColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final buttonBgColor = isDarkMode
        ? primaryColor.withValues(alpha: 0.2)
        : primaryColor.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: () => _finishOnboarding(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: buttonBgColor,
                    ),
                    child: Text(
                      context.tr('Pita', en: 'Skip'),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: pageController,
                itemCount: onboardingData.length,
                onPageChanged: (page) => currentPage.value = page,
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  final gradientColors = isDarkMode
                      ? (item['gradientDark'] as List<Color>)
                      : (item['gradientLight'] as List<Color>);

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon Container
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 600 + (index * 100)),
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: gradientColors,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    item['image'] as String,
                                    style: const TextStyle(fontSize: 70),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          item['description'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: subtextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicators and Navigation
            Expanded(
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: currentPage.value == index ? 32 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: currentPage.value == index
                              ? primaryColor
                              : indicatorColor,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Navigation Buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        // Back Button
                        if (currentPage.value > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                pageController.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                context.tr('Rudi', en: 'Back'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        if (currentPage.value > 0) const SizedBox(width: 12),

                        // Next/Get Started Button
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (currentPage.value <
                                  onboardingData.length - 1) {
                                pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              } else {
                                _finishOnboarding(context);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              currentPage.value < onboardingData.length - 1
                                  ? context.tr('Endelea', en: 'Continue')
                                  : context.tr('Anza Sasa', en: 'Get Started'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
