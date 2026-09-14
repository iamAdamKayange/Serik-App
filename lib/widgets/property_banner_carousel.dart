import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class PropertyBannerCarousel extends StatefulWidget {
  const PropertyBannerCarousel({super.key});

  @override
  State<PropertyBannerCarousel> createState() => _PropertyBannerCarouselState();
}

class _PropertyBannerCarouselState extends State<PropertyBannerCarousel>
    with SingleTickerProviderStateMixin {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;
  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<BannerItem> _banners = [
    BannerItem(
      image: 'assets/images/house1.jpeg',
      headline: 'Find Your Perfect Home',
      description: 'Discover comfortable rentals near you',
    ),
    BannerItem(
      image: 'assets/images/house2.jpeg',
      headline: 'Comfortable Homes, Better Living',
      description: 'Quality housing at affordable prices',
    ),
    BannerItem(
      image: 'assets/images/house3.jpeg',
      headline: 'Discover Your Next Home',
      description: 'Browse verified properties in your area',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _textAnimationController.forward();
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, CarouselPageChangedReason reason) {
    setState(() {
      _currentIndex = index;
    });
    _textAnimationController.reset();
    _textAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF46D39A);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Carousel
            CarouselSlider.builder(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.easeInOut,
                enlargeCenterPage: false,
                onPageChanged: _onPageChanged,
                scrollDirection: Axis.horizontal,
              ),
              itemCount: _banners.length,
              itemBuilder: (context, index, realIndex) {
                final banner = _banners[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.asset(
                      banner.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFE2E8F0),
                          child: Icon(
                            Icons.home,
                            size: 64,
                            color: isDark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                        );
                      },
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    // Text Content
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: AnimatedBuilder(
                        animation: _textAnimationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner.headline,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner.description,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Page Indicators
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                children: List.generate(
                  _banners.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? primaryColor
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerItem {
  final String image;
  final String headline;
  final String description;

  BannerItem({
    required this.image,
    required this.headline,
    required this.description,
  });
}
