import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/pages/admin_map_page.dart';
import 'package:serkapp/pages/home_page.dart';
import 'package:serkapp/pages/house_registration_page.dart';
import 'package:serkapp/pages/houses_page.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/model/house_data.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../model/tenant_model.dart';
import '../model/payment_model.dart';
import '../model/maintenance_model.dart';
import '../widgets/stat_card.dart';
import '../widgets/action_card.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      final fetchedHousesData = await ApiService.getMyHouses();
      if (!mounted) return;
      final List<HouseData> fetchedHouses = fetchedHousesData
          .map((json) => HouseData.fromJson(json as Map<String, dynamic>))
          .toList();
      setState(() {
        houses = fetchedHouses;
        _loadSampleData();
        _calculateStats();
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

  void _loadSampleData() {
    tenants = [];
    if (houses.isNotEmpty) {
      tenants.add(
        TenantData(
          id: '1',
          name: 'Adam Kayange',
          phone: '0712345678',
          houseId: houses[0].id,
          houseName: houses[0].name,
          rentAmount: houses[0].rentPrice,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().add(const Duration(days: 305)),
          status: 'Active',
        ),
      );
    }
    if (houses.length > 1) {
      tenants.add(
        TenantData(
          id: '2',
          name: 'Yusuph Mwashi',
          phone: '0755123456',
          houseId: houses[1].id,
          houseName: houses[1].name,
          rentAmount: houses[1].rentPrice,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 335)),
          status: 'Active',
        ),
      );
    }

    payments = [];
    if (tenants.isNotEmpty) {
      payments.add(
        PaymentData(
          id: '1',
          tenantName: tenants[0].name,
          tenantId: tenants[0].id,
          amount: tenants[0].rentAmount,
          date: DateTime.now().subtract(const Duration(days: 5)),
          status: 'Paid',
          month: DateFormat('MMMM yyyy').format(DateTime.now()),
        ),
      );
    }
    if (tenants.length > 1) {
      payments.add(
        PaymentData(
          id: '2',
          tenantName: tenants[1].name,
          tenantId: tenants[1].id,
          amount: tenants[1].rentAmount,
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: 'Pending',
          month: DateFormat('MMMM yyyy').format(DateTime.now()),
        ),
      );
    }

    maintenanceRequests = [];
    if (houses.isNotEmpty) {
      maintenanceRequests.add(
        MaintenanceData(
          id: '1',
          tenantName: tenants.isNotEmpty ? tenants[0].name : 'Mpangaji',
          houseName: houses[0].name,
          issue: 'Mfereji unatoboka',
          priority: 'High',
          status: 'Inasubiri',
          date: DateTime.now().subtract(const Duration(days: 2)),
          assignedTo: 'Fundi Juma',
        ),
      );
    }
    if (houses.length > 1) {
      maintenanceRequests.add(
        MaintenanceData(
          id: '2',
          tenantName: tenants.length > 1 ? tenants[1].name : 'Mpangaji',
          houseName: houses[1].name,
          issue: 'Taa haiwashi',
          priority: 'Medium',
          status: 'Inarudiwa',
          date: DateTime.now().subtract(const Duration(days: 1)),
          assignedTo: 'Fundi Ali',
        ),
      );
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
    _totalMonthlyIncome = houses.fold(0.0, (sum, house) {
      if (house.status.toLowerCase() == "imekodishwa" ||
          house.status.toLowerCase() == "imemalizika") {
        return sum + house.rentPrice;
      }
      return sum;
    });
  }

  void _showAddHouseForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HouseRegistrationForm(onHouseAdded: (newHouse) => _refreshData()),
      ),
    );
  }

  // ==================== FIXED LOGOUT ====================
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await ApiService.logout(); // clear token from secure storage
    authProvider.logout(); // clear provider state
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // ==================== PROFILE DIALOG (USING AUTH PROVIDER) ====================
  void _showProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.person,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('Taarifa za Akaunti', en: 'Account Information'),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow(
              Icons.person_outline,
              context.tr('Jina', en: 'Name'),
              authProvider.userName ?? context.tr('Mpangishaji', en: 'Landlord'),
            ),
            const SizedBox(height: 8),
            _buildProfileRow(
              Icons.email_outlined,
              context.tr('Barua Pepe', en: 'Email'),
              authProvider.userEmail ?? "email@example.com",
            ),
            const SizedBox(height: 8),
            _buildProfileRow(
              Icons.phone_android,
              context.tr('Simu', en: 'Phone'),
              authProvider.phone ?? context.tr('Hakuna', en: 'None'),
            ),
            const SizedBox(height: 8),
            _buildProfileRow(
              Icons.admin_panel_settings,
              context.tr('Aina', en: 'Type'),
              authProvider.userRole ?? "landlord",
            ),
            const Divider(),
            Text(
              ': ',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
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
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('Toka', en: 'Logout')),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : Colors.grey[50]!;
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    Color cardShadowColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.1);
    Color appBarGradientEnd = isDarkMode
        ? const Color(0xFF388E3C)
        : const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(themeProvider, primaryColor, isDarkMode),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: _currentTabIndex == 0
            ? _buildDashboard(
                isDarkMode,
                primaryColor,
                backgroundColor,
                surfaceColor,
                textColor,
                subtextColor,
                cardShadowColor,
                appBarGradientEnd,
              )
            : _buildCurrentTab(
                isDarkMode,
                surfaceColor,
                textColor,
                subtextColor,
                primaryColor,
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        isDarkMode,
        surfaceColor,
        primaryColor,
        cardShadowColor,
      ),
      floatingActionButton: _currentTabIndex == 0
          ? _buildFloatingButton(primaryColor)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeProvider themeProvider,
    Color primaryColor,
    bool isDarkMode,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('Mpangishaji Pro', en: 'Landlord Pro'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: isDarkMode
                ? context.tr('Badilisha hadi Mwangaza', en: 'Switch to Light')
                : context.tr('Badilisha hadi Giza', en: 'Switch to Dark'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () =>
              CustomDialogs.showSuccess(
                context,
                context.tr('Hakuna arifa mpya', en: 'No new notifications'),
              ),
        ),
        // 🔥 PROFILE BUTTON – now uses the real profile dialog
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: _showProfileDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshData,
        ),
      ],
    );
  }

  // ==================== BOTTOM NAVIGATION BAR ====================
  Widget _buildBottomNavigationBar(
    bool isDarkMode,
    Color surfaceColor,
    Color primaryColor,
    Color cardShadowColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Nyumbani",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: "Wapangaji",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_rounded),
            label: "Malipo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman_rounded),
            label: "Matengenezo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: "Taarifa",
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(Color primaryColor) {
    return FloatingActionButton(
      onPressed: _showAddHouseForm,
      backgroundColor: primaryColor,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  Widget _buildCurrentTab(
    bool isDarkMode,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
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

  // ==================== DASHBOARD COMPONENTS (unchanged) ====================
  Widget _buildDashboard(
    bool isDarkMode,
    Color primaryColor,
    Color backgroundColor,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color cardShadowColor,
    Color appBarGradientEnd,
  ) {
    return FadeTransition(
      opacity: _animationController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeMessage(isDarkMode, primaryColor, appBarGradientEnd),
            const SizedBox(height: 20),
            _buildAnimatedCarousel(isDarkMode, primaryColor, appBarGradientEnd),
            const SizedBox(height: 24),
            _buildStatsGrid(isDarkMode, primaryColor, textColor, subtextColor),
            const SizedBox(height: 24),
            _buildActionButtons(isDarkMode, primaryColor),
            const SizedBox(height: 16),
            _buildRecentActivity(
              isDarkMode,
              surfaceColor,
              textColor,
              subtextColor,
              primaryColor,
              cardShadowColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(
    bool isDarkMode,
    Color primaryColor,
    Color appBarGradientEnd,
  ) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = "Habari za asubuhi";
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = "Habari za mchana";
      greetingIcon = Icons.sunny;
    } else {
      greeting = "Habari za jioni";
      greetingIcon = Icons.nightlight_round;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, appBarGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$greeting!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Karibu kwenye dashibodi yako",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(greetingIcon, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCarousel(
    bool isDarkMode,
    Color primaryColor,
    Color appBarGradientEnd,
  ) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (houses.isEmpty) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, appBarGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_home_rounded, size: 48, color: Colors.white70),
              SizedBox(height: 8),
              Text(
                "Karibu! Anza kwa kuongeza nyumba yako ya kwanza",
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
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
            height: 200,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            enableInfiniteScroll: true,
            viewportFraction: 0.95,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() => _currentCarouselIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final house = houses[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, appBarGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            house.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
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
                          const SizedBox(height: 4),
                          Text(
                            "TZS ${NumberFormat('#,###').format(house.rentPrice)}/mwezi",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: house.status == "Imekodishwa"
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              house.status,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: houses.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCarouselIndex == entry.key ? 24 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _currentCarouselIndex == entry.key
                    ? primaryColor
                    : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
  ) {
    final stats = [
      {
        "title": "Nyumba",
        "value": houses.length.toString(),
        "icon": Icons.home_rounded,
        "color": primaryColor,
      },
      {
        "title": "Imekodishwa",
        "value": "$_occupiedHouses/${houses.length}",
        "icon": Icons.check_circle_outline_rounded,
        "color": Colors.green,
      },
      {
        "title": "Wapangaji",
        "value": "$_totalTenants",
        "icon": Icons.people_rounded,
        "color": const Color(0xFFFF8F00),
      },
      {
        "title": "Mapato (Mwezi)",
        "value": "TZS ${NumberFormat('#,###').format(_totalMonthlyIncome)}",
        "icon": Icons.monetization_on_rounded,
        "color": const Color(0xFFE65100),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        Widget card = StatCard(
          title: stat["title"] as String,
          value: stat["value"] as String,
          icon: stat["icon"] as IconData,
          color: stat["color"] as Color,
        );

        // Kadi ya kwanza (Nyumba) inabonyezwa
        if (index == 0) {
          card = GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HousesPage(houses: houses, onRefresh: _refreshData),
                ),
              );
            },
            child: card,
          );
        }

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 500 + (index * 100)),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value, child: child),
            );
          },
          child: card,
        );
      },
    );
  }

  Widget _buildActionButtons(bool isDarkMode, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: ActionCard(
            title: "Wapangaji",
            icon: Icons.person_add_rounded,
            color: const Color(0xFF2E7D32),
            onTap: () => CustomDialogs.showSuccess(
              context,
              "Fungua sehemu ya Wapangaji",
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActionCard(
            title: "Ramani",
            icon: Icons.map_rounded,
            color: const Color(0xFF2196F3),
            onTap: () => _navigateToAdminMap(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActionCard(
            title: "Matengenezo",
            icon: Icons.handyman_rounded,
            color: const Color(0xFF00695C),
            onTap: () => CustomDialogs.showSuccess(
              context,
              "Fungua sehemu ya Matengenezo",
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAdminMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminMapPage()),
    );
  }

  Widget _buildRecentActivity(
    bool isDarkMode,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
    Color cardShadowColor,
  ) {
    final recentPayments = payments.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Shughuli za Karibuni",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentPayments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    "Hakuna shughuli za hivi karibuni",
                    style: TextStyle(color: subtextColor),
                  ),
                ),
              )
            else
              ...recentPayments.map(
                (payment) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: payment.status == 'Paid'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      payment.status == 'Paid'
                          ? Icons.check_circle
                          : Icons.pending,
                      color: payment.status == 'Paid'
                          ? Colors.green
                          : Colors.orange,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    payment.tenantName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    payment.month,
                    style: TextStyle(color: subtextColor),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "TZS ${NumberFormat('#,###').format(payment.amount)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        payment.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: payment.status == 'Paid'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



