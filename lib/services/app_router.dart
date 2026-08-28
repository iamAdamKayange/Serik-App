import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/screen/splash_screen.dart';
import 'package:serik/screen/onboarding_screen.dart';
import 'package:serik/pages/home_page.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/pages/register_page.dart';
import 'package:serik/pages/rental_home_page.dart';
import 'package:serik/pages/custom_map_page.dart';
import 'package:serik/pages/admin_map_page.dart';
import 'package:serik/pages/notification_screen.dart';
import 'package:serik/pages/video_feed_page.dart';
import 'package:serik/pages/university_detail_page.dart';
import 'package:serik/pages/profile_edit_page.dart';
import 'package:serik/pages/app_settings_page.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/pages/house_registration_page.dart';
import 'package:serik/pages/houses_page.dart';
import 'package:serik/pages/tenants_page.dart';
import 'package:serik/pages/payments_page.dart';
import 'package:serik/pages/maintenance_page.dart';
import 'package:serik/pages/reports_page.dart';
import 'package:serik/pages/smart_alert_settings_page.dart';
import 'package:serik/pages/tenant_applications_page.dart';
import 'package:serik/model/rental_model.dart';

/// App Router Configuration with proper navigation management
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isLoggedIn;
      final isLandlord = authProvider.isLandlord;
      final isNormalUser = authProvider.isNormalUser;

      // Check if user is trying to access protected routes
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isLandlordRoute = state.matchedLocation.startsWith('/landlord');
      final isHomeRoute = state.matchedLocation.startsWith('/home');

      // Redirect to onboarding if first time
      // Note: This would need shared_preferences check in production

      // Redirect unauthenticated users to login (except public routes)
      if (!isLoggedIn &&
          !isAuthRoute &&
          !isOnboardingRoute &&
          state.matchedLocation != '/') {
        return '/login';
      }

      // Role-based routing for authenticated users
      if (isLoggedIn) {
        // Redirect landlords to landlord dashboard when accessing home routes
        if (isLandlord && isHomeRoute) {
          return '/landlord/dashboard';
        }

        // Redirect normal users to home when accessing landlord routes
        if (isNormalUser && isLandlordRoute) {
          return '/home';
        }

        // If logged in and trying to access auth routes, redirect to appropriate dashboard
        if (isAuthRoute) {
          return isLandlord ? '/landlord/dashboard' : '/home';
        }
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SplashScreen()),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const OnboardingScreen()),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginPage()),
      ),

      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RegisterPage()),
      ),

      // Main App (Regular User)
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HomePage()),
        routes: [
          GoRoute(
            path: 'university/:name',
            pageBuilder: (context, state) {
              final universityName = state.pathParameters['name']!;
              // Find university data (this would need to be passed properly)
              return MaterialPage(
                key: state.pageKey,
                child: UniversityDetailPage(
                  university: {
                    'name': universityName,
                    // Add other university data
                  },
                ),
              );
            },
          ),
          GoRoute(
            path: 'map',
            pageBuilder: (context, state) =>
                MaterialPage(key: state.pageKey, child: const CustomMapPage()),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const NotificationScreen(),
            ),
          ),
          GoRoute(
            path: 'videos',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const VideoFeedPage(isVisible: true),
            ),
          ),
          GoRoute(
            path: 'applications',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const TenantApplicationsPage(),
            ),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AppSettingsPage(),
            ),
          ),
          GoRoute(
            path: 'profile/edit',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfileEditPage(),
            ),
          ),
        ],
      ),

      // Landlord Dashboard Routes
      GoRoute(
        path: '/landlord',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RentalHomePage()),
        routes: [
          GoRoute(
            path: 'dashboard',
            pageBuilder: (context, state) =>
                MaterialPage(key: state.pageKey, child: const RentalHomePage()),
          ),
          GoRoute(
            path: 'houses',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: HousesPage(houses: [], onRefresh: () async {}),
            ),
          ),
          GoRoute(
            path: 'houses/add',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: HouseRegistrationForm(onHouseAdded: (house) {}),
            ),
          ),
          GoRoute(
            path: 'tenants',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: TenantsPage(tenants: [], onAddTenant: () {}),
            ),
          ),
          GoRoute(
            path: 'payments',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: PaymentsPage(payments: []),
            ),
          ),
          GoRoute(
            path: 'maintenance',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: MaintenancePage(maintenanceRequests: []),
            ),
          ),
          GoRoute(
            path: 'reports',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: ReportsPage(
                payments: [],
                totalHouses: 0,
                occupiedHouses: 0,
                totalTenants: 0,
              ),
            ),
          ),
          GoRoute(
            path: 'map',
            pageBuilder: (context, state) =>
                MaterialPage(key: state.pageKey, child: const AdminMapPage()),
          ),
          GoRoute(
            path: 'alerts',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SmartAlertSettingsPage(),
            ),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AppSettingsPage(),
            ),
          ),
          GoRoute(
            path: 'profile/edit',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfileEditPage(),
            ),
          ),
        ],
      ),

      // Property Detail (Shared)
      GoRoute(
        path: '/property/:id',
        pageBuilder: (context, state) {
          final spot = state.extra as RentalSpot?;

          if (spot == null) {
            return MaterialPage(
              key: state.pageKey,
              child: Scaffold(
                appBar: AppBar(title: const Text('Property')),
                body: const Center(
                  child: Text('Property information is not available.'),
                ),
              ),
            );
          }

          return MaterialPage(
            key: state.pageKey,
            child: RentalDetailScreen(spot: spot),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Navigation helper methods
class NavigationHelper {
  static void navigateToHome(BuildContext context) {
    context.go('/home');
  }

  static void navigateToLogin(BuildContext context) {
    context.go('/login');
  }

  static void navigateToRegister(BuildContext context) {
    context.go('/register');
  }

  static void navigateToLandlordDashboard(BuildContext context) {
    context.go('/landlord/dashboard');
  }

  static void navigateToPropertyDetail(
    BuildContext context,
    String propertyId,
  ) {
    context.go('/property/$propertyId');
  }

  static void navigateToUniversityDetail(
    BuildContext context,
    String universityName,
  ) {
    context.go('/home/university/$universityName');
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
