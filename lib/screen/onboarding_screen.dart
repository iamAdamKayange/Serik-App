import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
//import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serkapp/pages/home_page.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);

    final onboardingData = [
      {
        'title': 'Pata Nyumba Bora',
        'description':
            'Tafuta nyumba za kupanga katika maeneo mbalimbali kwa bei nafuu na mazingira salama',
        'icon': Icons.search_rounded,
        'color': Color(0xFF2E7D32),
        'image': '🏠',
      },
      {
        'title': 'Wasiliana Moja kwa Moja',
        'description': 'Wasiliana na wakodisha bila mwingiliano wa mtu wa tatu',
        'icon': Icons.chat_rounded,
        'color': Color(0xFF1976D2),
        'image': '💬',
      },
      {
        'title': 'Malipo Salama',
        'description':
            'Fanya malipo yako kwa usalama na upate hati rasmi ya kukodisha',
        'icon': Icons.security_rounded,
        'color': Color(0xFFF57C00),
        'image': '🔒',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                  child: Text(
                    'Pita',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji/Image Placeholder
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (item['color'] as Color).withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item['image'] as String,
                              style: TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        Text(
                          item['description'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[700],
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
                        duration: Duration(milliseconds: 300),
                        width: currentPage.value == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: currentPage.value == index
                              ? Colors.blue
                              : Colors.grey.shade300,
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
                          TextButton(
                            onPressed: () {
                              pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              'Rudi',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),

                        // Next/Get Started Button
                        Container(
                          decoration: BoxDecoration(color: Colors.white),
                          width: 150,
                          height: 50,
                          child: FilledButton(
                            onPressed: () {
                              if (currentPage.value <
                                  onboardingData.length - 1) {
                                pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              currentPage.value < onboardingData.length - 1
                                  ? 'Endelea'
                                  : 'Anza Sasa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
