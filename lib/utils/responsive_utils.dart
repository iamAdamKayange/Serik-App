import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileSmall = 360;
  static const double mobileMedium = 400;
  static const double mobileLarge = 480;
  static const double tablet = 768;
  static const double desktop = 1024;

  // Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileSmall) return ScreenSize.mobileSmall;
    if (width < mobileMedium) return ScreenSize.mobileMedium;
    if (width < mobileLarge) return ScreenSize.mobileLarge;
    if (width < tablet) return ScreenSize.mobileExtraLarge;
    if (width < desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  // Responsive padding
  static double getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 12;
      case ScreenSize.mobileMedium:
        return 14;
      case ScreenSize.mobileLarge:
        return 16;
      case ScreenSize.mobileExtraLarge:
        return 18;
      case ScreenSize.tablet:
        return 24;
      case ScreenSize.desktop:
        return 32;
    }
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 8;
      case ScreenSize.mobileMedium:
        return 10;
      case ScreenSize.mobileLarge:
        return 12;
      case ScreenSize.mobileExtraLarge:
        return 14;
      case ScreenSize.tablet:
        return 16;
      case ScreenSize.desktop:
        return 20;
    }
  }

  // Responsive container width
  static double getResponsiveContainerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= desktop) {
      return 1200;
    } else if (screenWidth >= tablet) {
      return screenWidth * 0.9;
    } else {
      return screenWidth;
    }
  }

  // Responsive card radius
  static double getResponsiveRadius(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 12;
      case ScreenSize.mobileMedium:
        return 14;
      case ScreenSize.mobileLarge:
        return 16;
      case ScreenSize.mobileExtraLarge:
        return 18;
      case ScreenSize.tablet:
        return 20;
      case ScreenSize.desktop:
        return 24;
    }
  }

  // Responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 18;
      case ScreenSize.mobileMedium:
        return 20;
      case ScreenSize.mobileLarge:
        return 22;
      case ScreenSize.mobileExtraLarge:
        return 24;
      case ScreenSize.tablet:
        return 26;
      case ScreenSize.desktop:
        return 28;
    }
  }

  // Responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
      case ScreenSize.mobileMedium:
        return 1;
      case ScreenSize.mobileLarge:
      case ScreenSize.mobileExtraLarge:
        return 2;
      case ScreenSize.tablet:
        return 3;
      case ScreenSize.desktop:
        return 4;
    }
  }

  // Responsive image height
  static double getResponsiveImageHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 140;
      case ScreenSize.mobileMedium:
        return 160;
      case ScreenSize.mobileLarge:
        return 180;
      case ScreenSize.mobileExtraLarge:
        return 200;
      case ScreenSize.tablet:
        return 220;
      case ScreenSize.desktop:
        return 240;
    }
  }

  // Responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 44;
      case ScreenSize.mobileMedium:
        return 46;
      case ScreenSize.mobileLarge:
        return 48;
      case ScreenSize.mobileExtraLarge:
        return 50;
      case ScreenSize.tablet:
        return 52;
      case ScreenSize.desktop:
        return 56;
    }
  }

  // Responsive aspect ratio for cards
  static double getResponsiveCardAspectRatio(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobileSmall:
        return 1.2;
      case ScreenSize.mobileMedium:
        return 1.1;
      case ScreenSize.mobileLarge:
        return 1.0;
      case ScreenSize.mobileExtraLarge:
        return 0.95;
      case ScreenSize.tablet:
        return 0.9;
      case ScreenSize.desktop:
        return 0.85;
    }
  }
}

enum ScreenSize {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  mobileExtraLarge,
  tablet,
  desktop,
}
