import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/pages/admin_map_page.dart';
import 'package:serik/pages/app_settings_page.dart';
import 'package:serik/pages/home_page.dart';
import 'package:serik/pages/house_registration_page.dart';
import 'package:serik/pages/houses_page.dart';
import 'package:serik/pages/landlord_verification_page.dart';
import 'package:serik/pages/notification_screen.dart';
import 'package:serik/pages/profile_edit_page.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/utils/app_typography.dart';
import 'package:serik/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../model/tenant_model.dart';
import '../model/payment_model.dart';
import '../model/maintenance_model.dart';
import '../widgets/custom_dialogs.dart';
import 'tenants_page.dart';
import 'payments_page.dart';
import 'maintenance_page.dart';
import 'reports_page.dart';

class RentalHomePage extends StatefulWidget {
  const RentalHomePage({super.key});

  @override
  State<RentalHomePage> createState() => _RentalHomePageState();
}

class _RentalHomePageState extends State<RentalHomePage>
    with SingleTickerProviderStateMixin {
  // Color constants
  static const _darkPrimary = Color(0xFF46D39A);
  static const _lightPrimary = Color(0xFF0F8B61);
  static const _darkSurface = Color(0xFF141A17);
  static const _darkText = Color(0xFFF0F5F2);
  static const _lightText = Color(0xFF111C17);
  static const _darkSubtext = Color(0xFF8A9490);
  static const _lightSubtext = Color(0xFF5E6E68);

  List<HouseData> houses = [];
  List<TenantData> tenants = [];
  List<PaymentData> payments = [];
  List<MaintenanceData> maintenanceRequests = [];
  bool _isLoading = true;
  int _currentCarouselIndex = 0;
  int _currentTabIndex = 0;
  late AnimationController _animationController;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  double _totalMonthlyIncome = 0;
  int _totalTenants = 0;
  int _occupiedHouses = 0;
  bool _isProfileComplete = false;
  Map<String, dynamic>? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _refreshData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getMyHouses(),
        ApiService.getVerificationStatus(),
      ]);
      final fetchedHousesData = results[0] as List<dynamic>;
      final verificationStatus = results[1] is Map<String, dynamic>
          ? Map<String, dynamic>.from(results[1] as Map)
          : null;
      if (!mounted) return;
      final List<HouseData> fetchedHouses = fetchedHousesData
          .map((json) => HouseData.fromJson(json as Map<String, dynamic>))
          .toList();
      setState(() {
        houses = fetchedHouses;
        _verificationStatus = verificationStatus;
        tenants = [];
        payments = [];
        maintenanceRequests = [];
        _calculateStats();
        _checkProfileStatus();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomDialogs.showError(
        context,
        context.tr(
          'Imeshindwa kupakia data. Jaribu tena.',
          en: 'Could not load data. Please try again.',
        ),
      );
    }
  }

  void _checkProfileStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_verificationStatus != null) {
      _isProfileComplete = _verificationStatus!['canPublish'] as bool? ?? false;
    } else {
      _isProfileComplete = authProvider.isProfileComplete;
    }
  }

  void _calculateStats() {
    _totalTenants = tenants.length;
    _occupiedHouses = houses
        .where(
          (h) =>
              h.status.toLowerCase() == "imekodishwa" ||
              h.status.toLowerCase() == "imemalizika",
        )
        .length;
    _totalMonthlyIncome = houses.fold(0.0, (sum, h) {
      if (h.status.toLowerCase() == "imekodishwa" ||
          h.status.toLowerCase() == "imemalizika") {
        return sum + h.rentPrice;
      }
      return sum;
    });
  }

  void _showAddHouseForm() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is landlord and verified
    if (auth.isLandlord) {
      try {
        // Check verification status
        final verificationStatus = await ApiService.getVerificationStatus();
        
        if (verificationStatus != null &&
            (verificationStatus['identityStatus'] != 'verified' || 
             verificationStatus['propertyStatus'] != 'verified')) {
          // Show verification required dialog
          if (mounted) {
            _showVerificationRequiredDialog(verificationStatus);
          }
          return;
        }
      } catch (e) {
        // If we can't check verification status, allow them to proceed (backend will handle it)
        debugPrint('Could not check verification status: $e');
      }
    }
    
    // Allow house registration if verified or verification check failed
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HouseRegistrationForm(onHouseAdded: (_) => _refreshData()),
        ),
      );
    }
  }

  void _showVerificationRequiredDialog(Map<String, dynamic> verificationStatus) {
    final identityStatus = verificationStatus['identityStatus'] ?? 'unknown';
    final propertyStatus = verificationStatus['propertyStatus'] ?? 'unknown';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.orange),
            const SizedBox(width: 8),
            Text(context.tr('Uhakiki Unahitajika', en: 'Verification Required')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'Lazima uwe verified kama mwenye nyumba kabla ya kuweka nyumba.',
                en: 'You must be verified as a landlord before adding houses.',
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildVerificationStatusItem(
              context.tr('Uhakiki wa Identity', en: 'Identity Verification'),
              identityStatus,
            ),
            const SizedBox(height: 8),
            _buildVerificationStatusItem(
              context.tr('Uhakiki wa Mali', en: 'Property Verification'),
              propertyStatus,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Funga', en: 'Close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LandlordVerificationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('Nenda kwa Uhakiki', en: 'Go to Verification')),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusItem(String label, String status) {
    IconData icon;
    Color color;
    
    switch (status.toLowerCase()) {
      case 'verified':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'pending':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${status.toUpperCase()}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await ApiService.logout();
    auth.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  void _showProfileDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final primary = AppTheme.getPrimary(isDark);
    final surface = AppTheme.getSurface(isDark);
    final textCol = AppTheme.getText(isDark);
    final subCol = AppTheme.getSubtext(isDark);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: auth.avatarUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Text(
                              (auth.userName ?? 'L')[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              (auth.userName ?? 'L')[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          (auth.userName ?? 'L')[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                auth.userName ?? context.tr('Mpangishaji', en: 'Landlord'),
                style: GoogleFonts.poppins(
                  color: textCol,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.userEmail ?? '',
                style: GoogleFonts.poppins(color: subCol, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _profileTile(
                Icons.phone_android,
                context.tr('Simu', en: 'Phone'),
                auth.phone ?? context.tr('Hakuna', en: 'None'),
                primary,
                textCol,
                subCol,
                isDark,
              ),
              const SizedBox(height: 8),
              _profileTile(
                Icons.admin_panel_settings,
                context.tr('Aina', en: 'Role'),
                auth.userRole ?? 'landlord',
                primary,
                textCol,
                subCol,
                isDark,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      (_isProfileComplete
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        (_isProfileComplete
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isProfileComplete
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: _isProfileComplete
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isProfileComplete
                          ? context.tr(
                              'Profaili Imekamilika',
                              en: 'Profile Verified',
                            )
                          : context.tr(
                              'Kamilisha Profaili',
                              en: 'Profile Incomplete',
                            ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isProfileComplete
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        context.tr('Hariri Profaili', en: 'Edit Profile'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: subCol,
                        side: BorderSide(color: subCol.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppSettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: Text(
                        context.tr('Mipangilio', en: 'Settings'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: subCol,
                        side: BorderSide(color: subCol.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: subCol,
                        side: BorderSide(color: subCol.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        context.tr('Funga', en: 'Close'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (!_isProfileComplete) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LandlordVerificationPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          context.tr('Kamilisha', en: 'Verify'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        context.tr('Toka', en: 'Logout'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTile(
    IconData icon,
    String label,
    String value,
    Color primary,
    Color textCol,
    Color subCol,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.getSurface2(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: subCol,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: textCol),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primary = AppTheme.getPrimary(isDark);
    final bg = AppTheme.getBackground(isDark);
    final surface = AppTheme.getSurface(isDark);
    final textCol = AppTheme.getText(isDark);
    final subCol = AppTheme.getSubtext(isDark);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.06);
    final landlordName =
        authProvider.userName ?? context.tr('Mpangishaji', en: 'Landlord');

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(themeProvider, primary, isDark, landlordName),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primary,
        backgroundColor: surface,
        child: _currentTabIndex == 0
            ? _dashboard(
                isDark,
                primary,
                bg,
                surface,
                textCol,
                subCol,
                shadow,
                landlordName,
              )
            : _tabContent(isDark, surface, textCol, subCol, primary),
      ),
      bottomNavigationBar: _bottomNav(isDark, surface, primary, shadow),
      floatingActionButton: _currentTabIndex == 0 ? _fab(primary) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar(
    ThemeProvider tp,
    Color primary,
    bool isDark,
    String name,
  ) {
    return AppBar(
      backgroundColor: AppTheme.getSurface(isDark),
      elevation: 0,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/seriki.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Serik',
                  style: AppTypography.headline3.copyWith(
                    color: AppTheme.getText(isDark),
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  name,
                  style: AppTypography.bodySmall.copyWith(
                    color: primary.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _navIcon(
          Icons.map_outlined,
          isDark,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMapPage()),
          ),
        ),
        Stack(
          children: [
            _navIcon(
              Icons.notifications_outlined,
              isDark,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: ApiService.getNotifications(limit: 50),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.where((n) => n['read'] == false).length ?? 0;
                if (unreadCount == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        _navIcon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          isDark,
          () => tp.toggleTheme(),
        ),
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return GestureDetector(
              onTap: _showProfileDialog,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? _darkPrimary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: auth.avatarUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: isDark ? _darkPrimary : Colors.white,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: isDark ? _darkPrimary : Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: isDark ? _darkPrimary : Colors.white,
                      ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.3),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isDark, VoidCallback onTap) => IconButton(
    icon: Icon(icon, color: isDark ? _darkSubtext : Colors.white, size: 22),
    onPressed: onTap,
    splashRadius: 20,
  );

  // ── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _bottomNav(bool isDark, Color surface, Color primary, Color shadow) {
    final items = [
      (
        Icons.grid_view_rounded,
        Icons.grid_view_outlined,
        context.tr('Nyumbani', en: 'Home'),
      ),
      (
        Icons.people_rounded,
        Icons.people_outline_rounded,
        context.tr('Wapangaji', en: 'Tenants'),
      ),
      (
        Icons.account_balance_wallet_rounded,
        Icons.account_balance_wallet_outlined,
        context.tr('Malipo', en: 'Payments'),
      ),
      (
        Icons.handyman_rounded,
        Icons.handyman_outlined,
        context.tr('Matengenezo', en: 'Maintenance'),
      ),
      (
        Icons.bar_chart_rounded,
        Icons.bar_chart_outlined,
        context.tr('Taarifa', en: 'Reports'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = _currentTabIndex == i;
              final (activeIc, inactiveIc, label) = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentTabIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? primary.withValues(alpha: isDark ? 0.15 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sel ? activeIc : inactiveIc,
                          size: 22,
                          color: sel
                              ? primary
                              : (isDark ? _darkSubtext : _lightSubtext),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel
                                ? primary
                                : (isDark ? _darkSubtext : _lightSubtext),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _fab(Color primary) => FloatingActionButton(
    onPressed: _showAddHouseForm,
    backgroundColor: primary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
  );

  Widget _tabContent(
    bool isDark,
    Color surface,
    Color textCol,
    Color subCol,
    Color primary,
  ) {
    switch (_currentTabIndex) {
      case 1:
        return TenantsPage(tenants: tenants, onAddTenant: () {});
      case 2:
        return PaymentsPage(payments: payments);
      case 3:
        return MaintenancePage(maintenanceRequests: maintenanceRequests);
      case 4:
        return ReportsPage(
          payments: payments,
          totalHouses: houses.length,
          occupiedHouses: _occupiedHouses,
          totalTenants: _totalTenants,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── DASHBOARD ────────────────────────────────────────────────────────────
  Widget _dashboard(
    bool isDark,
    Color primary,
    Color bg,
    Color surface,
    Color textCol,
    Color subCol,
    Color shadow,
    String name,
  ) {
    return FadeTransition(
      opacity: _animationController,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeBanner(isDark, primary, name),
            const SizedBox(height: 16),
            if (!_isProfileComplete) ...[
              _verificationCard(isDark),
              const SizedBox(height: 16),
            ],
            _statsRow(isDark, primary, textCol, subCol, surface, shadow),
            const SizedBox(height: 20),
            _sectionTitle(
              context.tr('Nyumba Zangu', en: 'My Properties'),
              primary,
              textCol,
              center: false,
            ),
            const SizedBox(height: 12),
            _carousel(isDark, primary),
            const SizedBox(height: 20),
            _sectionTitle(
              context.tr('Vitendo vya Haraka', en: 'Quick Actions'),
              primary,
              textCol,
              center: false,
            ),
            const SizedBox(height: 12),
            _quickActions(isDark, primary, surface, shadow),
            const SizedBox(height: 20),
            _sectionTitle(
              context.tr('Shughuli za Karibuni', en: 'Recent Activity'),
              primary,
              textCol,
            ),
            const SizedBox(height: 12),
            _recentActivity(isDark, surface, textCol, subCol, shadow),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    Color primary,
    Color textCol, {
    bool center = false,
  }) {
    final titleWidget = Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textCol,
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );

    if (center) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            titleWidget,
          ],
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        titleWidget,
      ],
    );
  }

  // ── WELCOME BANNER ───────────────────────────────────────────────────────
  Widget _welcomeBanner(bool isDark, Color primary, String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? context.tr('Habari za asubuhi', en: 'Good Morning')
        : hour < 17
        ? context.tr('Habari za mchana', en: 'Good Afternoon')
        : context.tr('Habari za jioni', en: 'Good Evening');
    final icon = hour < 12
        ? Icons.wb_sunny_rounded
        : hour < 17
        ? Icons.sunny
        : Icons.nightlight_round;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome, $name 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'Hapa ndipo unaposimamia nyumba zako',
                    en: 'Manage all your properties here',
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: houses.isEmpty ? 0 : _occupiedHouses / houses.length,
                  strokeWidth: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white,
                ),
              ),
              Text(
                houses.isEmpty
                    ? '0%'
                    : '${((_occupiedHouses / houses.length) * 100).round()}%',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── VERIFICATION CARD ────────────────────────────────────────────────────
  Widget _verificationCard(bool isDark) {
    final locale = Localizations.localeOf(context);
    final isSw = locale.languageCode == 'sw';

    String statusText, message, buttonText;
    Color gradStart, gradEnd;

    if (_verificationStatus != null) {
      final canPublish = _verificationStatus!['canPublish'] as bool? ?? false;
      final identitySt =
          _verificationStatus!['identityStatus'] as String? ?? 'pending';
      final propertySt =
          _verificationStatus!['propertyStatus'] as String? ?? 'pending';

      if (canPublish) {
        statusText = isSw ? 'Umethibitishwa ✓' : 'Verified ✓';
        gradStart = const Color(0xFF4CAF50);
        gradEnd = const Color(0xFF81C784);
        message = isSw
            ? 'Unaweza kuweka nyumba zako sasa'
            : 'You can now list your properties';
        buttonText = isSw ? 'Angalia Nyumba' : 'View Properties';
      } else {
        gradStart = const Color(0xFFF59E0B);
        gradEnd = const Color(0xFFFBBF24);
        statusText = isSw ? 'Inasubiri Uthibitishaji' : 'Needs Verification';
        if (identitySt == 'pending' && propertySt == 'pending') {
          message = isSw
              ? 'Thibitisha utambulisho wako'
              : 'Verify your identity to list properties';
          buttonText = isSw ? 'Thibitisha' : 'Verify Now';
        } else if (identitySt == 'verified' && propertySt == 'pending') {
          message = isSw
              ? 'Thibitisha mali yako'
              : 'Verify your property to list it';
          buttonText = isSw ? 'Thibitisha Mali' : 'Verify Property';
        } else {
          message = isSw
              ? 'Inasubiri ukaguzi wa admin'
              : 'Awaiting admin review';
          buttonText = isSw ? 'Angalia Hali' : 'Check Status';
        }
      }
    } else {
      statusText = isSw ? 'Kamilisha Uthibitishaji' : 'Complete Verification';
      gradStart = const Color(0xFFF59E0B);
      gradEnd = const Color(0xFFFBBF24);
      message = isSw
          ? 'Thibitisha utambulisho wako ili kuweka nyumba'
          : 'Verify your identity to publish properties';
      buttonText = isSw ? 'Thibitisha' : 'Complete Verification';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradStart.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LandlordVerificationPage(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: gradStart,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ────────────────────────────────────────────────────────────
  Widget _statsRow(
    bool isDark,
    Color primary,
    Color textCol,
    Color subCol,
    Color surface,
    Color shadow,
  ) {
    final items = [
      _SI(
        label: context.tr('Nyumba', en: 'Properties'),
        value: '${houses.length}',
        icon: Icons.home_work_rounded,
        color: primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HousesPage(houses: houses, onRefresh: _refreshData),
          ),
        ),
      ),
      _SI(
        label: context.tr('Imekodishwa', en: 'Occupied'),
        value: '$_occupiedHouses/${houses.length}',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF22C55E),
      ),
      _SI(
        label: context.tr('Wapangaji', en: 'Tenants'),
        value: '$_totalTenants',
        icon: Icons.people_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _SI(
        label: context.tr('Mapato', en: 'Income'),
        value: 'TZS\n${NumberFormat('#,###').format(_totalMonthlyIncome)}',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF6366F1),
      ),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final s = items[i];
        return Expanded(
          child: GestureDetector(
            onTap: s.onTap,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + i * 80),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Transform.scale(
                scale: v,
                child: Opacity(opacity: v, child: child),
              ),
              child: Container(
                margin: EdgeInsets.only(right: i < items.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isDark
                      ? Border.all(color: const Color(0xFF26312D), width: 0.5)
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s.icon, size: 18, color: s.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 9.5, color: subCol),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── CAROUSEL ─────────────────────────────────────────────────────────────
  Widget _carousel(bool isDark, Color primary) {
    if (_isLoading) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: isDark ? _darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: CircularProgressIndicator(color: primary, strokeWidth: 2.5),
        ),
      );
    }
    if (houses.isEmpty) {
      return Center(
        child: GestureDetector(
          onTap: _showAddHouseForm,
          child: Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_home_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    'Ongeza nyumba yako ya kwanza',
                    en: 'Add your first property',
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('Gusa kuongeza', en: 'Tap to add'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: houses.length,
          options: CarouselOptions(
            height: 190,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            autoPlayCurve: Curves.easeInOut,
            enableInfiniteScroll: true,
            viewportFraction: 0.93,
            enlargeCenterPage: true,
            onPageChanged: (i, reason) => setState(() => _currentCarouselIndex = i),
          ),
          itemBuilder: (context, i, _) {
            final house = houses[i];
            final occupied = house.status == 'Imekodishwa';
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    top: -24,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: occupied
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  house.status,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                house.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      house.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'TZS ${NumberFormat('#,###').format(house.rentPrice)}/mo',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: houses.asMap().entries.map((e) {
            final active = _currentCarouselIndex == e.key;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: active
                    ? _lightPrimary
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────────────────────────────
  Widget _quickActions(
    bool isDark,
    Color primary,
    Color surface,
    Color shadow,
  ) {
    final actions = [
      _AI(
        label: context.tr('Wapangaji', en: 'Tenants'),
        icon: Icons.people_rounded,
        color: _lightPrimary,
        onTap: () => setState(() => _currentTabIndex = 1),
      ),
      _AI(
        label: context.tr('Malipo', en: 'Payments'),
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => setState(() => _currentTabIndex = 2),
      ),
      _AI(
        label: context.tr('Matengenezo', en: 'Maintenance'),
        icon: Icons.handyman_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => setState(() => _currentTabIndex = 3),
      ),
      _AI(
        label: context.tr('Taarifa', en: 'Reports'),
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => setState(() => _currentTabIndex = 4),
      ),
    ];

    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        return Expanded(
          child: GestureDetector(
            onTap: a.onTap,
            child: Container(
              margin: EdgeInsets.only(right: i < actions.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isDark
                    ? Border.all(color: const Color(0xFF26312D), width: 0.5)
                    : null,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, size: 22, color: a.color),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    a.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _darkText : _lightText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── RECENT ACTIVITY ──────────────────────────────────────────────────────
  Widget _recentActivity(
    bool isDark,
    Color surface,
    Color textCol,
    Color subCol,
    Color shadow,
  ) {
    final recent = payments.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
      ),
      child: recent.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  context.tr(
                    'Hakuna shughuli za hivi karibuni',
                    en: 'No recent activity',
                  ),
                  style: GoogleFonts.poppins(color: subCol, fontSize: 13),
                ),
              ),
            )
          : Column(
              children: List.generate(recent.length, (i) {
                final p = recent[i];
                final isPaid = p.status == 'Paid';
                final statusColor = isPaid
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B);
                return Column(
                  children: [
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.12 : 0.05,
                        ),
                      ),
                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                0.1 + i * 0.15,
                                1.0,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.tenantName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: textCol,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    p.month,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: subCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TZS ${NumberFormat('#,###').format(p.amount)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: textCol,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.status,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }
}

// Helper data classes
class _SI {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _SI({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _AI {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AI({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
