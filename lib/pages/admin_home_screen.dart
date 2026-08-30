import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  List<dynamic>? _verificationQueue;
  List<dynamic>? _recentUsers;
  List<dynamic>? _houses;
  List<dynamic>? _allUsers;
  List<dynamic>? _newRegistrations;
  // ignore: unused_field
  String _searchQuery = '';
  String _userFilter = 'all'; // all, verified, pending, banned
  String _houseFilter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAdminDashboard();
      final queue = await ApiService.getVerificationQueue();
      final users = await ApiService.getRecentUsers();
      final houses = await ApiService.getAllHouses();
      final allUsers = await ApiService.getAllUsers();
      final newRegs = await ApiService.getNewRegistrations();

      setState(() {
        _dashboardData = data;
        _verificationQueue = queue;
        _recentUsers = users;
        _houses = houses;
        _allUsers = allUsers;
        _newRegistrations = newRegs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final isSwahili = locale.languageCode == 'sw';

    final primaryColor = isDark
        ? const Color(0xFF46D39A)
        : const Color(0xFF0F8B61);
    final backgroundColor = isDark
        ? const Color(0xFF0D1110)
        : const Color(0xFFF7F9F8);
    final cardColor = isDark ? const Color(0xFF171C1A) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFF2F7F4)
        : const Color(0xFF15201C);
    final subtextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(
            isDark,
            primaryColor,
            cardColor,
            textColor,
            subtextColor,
            isSwahili,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(
                  isDark,
                  primaryColor,
                  cardColor,
                  textColor,
                  subtextColor,
                  isSwahili,
                ),
                // Content Area
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Color(0xFF46D39A),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isSwahili ? 'Inasubiri...' : 'Loading...',
                                style: GoogleFonts.poppins(
                                  color: subtextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildContent(
                          isDark,
                          primaryColor,
                          cardColor,
                          textColor,
                          subtextColor,
                          isSwahili,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    return Container(
      width: 280,
      color: cardColor,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: primaryColor),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Color(0xFF0F8B61),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'SERK Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Navigation Items
          _buildNavItem(
            Icons.dashboard_rounded,
            isSwahili ? 'Dashboard' : 'Dashboard',
            0,
            isDark,
            primaryColor,
            textColor,
            subtextColor,
          ),
          _buildNavItem(
            Icons.people_rounded,
            isSwahili ? 'Watumiaji' : 'Users',
            1,
            isDark,
            primaryColor,
            textColor,
            subtextColor,
          ),
          _buildNavItem(
            Icons.home_rounded,
            isSwahili ? 'Nyumba' : 'Houses',
            2,
            isDark,
            primaryColor,
            textColor,
            subtextColor,
          ),
          _buildNavItem(
            Icons.verified_user_rounded,
            isSwahili ? 'Uthibitishaji' : 'Verification',
            3,
            isDark,
            primaryColor,
            textColor,
            subtextColor,
          ),
          _buildNavItem(
            Icons.analytics_rounded,
            isSwahili ? 'Analytics' : 'Analytics',
            4,
            isDark,
            primaryColor,
            textColor,
            subtextColor,
          ),
          _buildNavItem(
            Icons.settings_rounded,
            isSwahili ? 'Mipangilio' : 'Settings',
            5,
            isDark,
            primaryColor,
            textColor,
            subtextColor,
          ),
          const Spacer(),
          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.red),
              title: Text(
                isSwahili ? 'Ondoka' : 'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : subtextColor,
          size: 24,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? primaryColor : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildTopBar(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF26312D) : const Color(0xFFE2E8E5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            isSwahili ? 'Dashboard ya Admin' : 'Admin Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          // Quick Actions
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: subtextColor),
            onPressed: _loadDashboardData,
            tooltip: isSwahili ? 'Pitia upya' : 'Refresh',
          ),
          const SizedBox(width: 8),
          // User Profile
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.userName ?? 'Admin',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
      case 1:
        return _buildUsersContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
      case 2:
        return _buildHousesContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
      case 3:
        return _buildVerificationContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
      case 4:
        return _buildAnalyticsContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
      case 5:
        return _buildSettingsContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
      default:
        return _buildDashboardContent(
          isDark,
          primaryColor,
          cardColor,
          textColor,
          subtextColor,
          isSwahili,
        );
    }
  }

  Widget _buildDashboardContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final totalUsers = _dashboardData?['totalUsers'] ?? _allUsers?.length ?? 0;
    final totalHouses = _dashboardData?['totalHouses'] ?? _houses?.length ?? 0;
    final pendingVerifications = _verificationQueue?.length ?? 0;
    final revenue = _dashboardData?['revenue']?.toString() ?? '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  Icons.people_rounded,
                  isSwahili ? 'Watumiaji' : 'Users',
                  '$totalUsers',
                  isDark,
                  primaryColor,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.home_rounded,
                  isSwahili ? 'Nyumba' : 'Houses',
                  '$totalHouses',
                  isDark,
                  primaryColor,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.verified_user_rounded,
                  isSwahili ? 'Uthibitishaji' : 'Verifications',
                  '$pendingVerifications',
                  isDark,
                  primaryColor,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.monetization_on_rounded,
                  isSwahili ? 'Mapato' : 'Revenue',
                  revenue,
                  isDark,
                  primaryColor,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Activity
          _buildSectionCard(
            Icons.history_rounded,
            isSwahili ? 'Watumiaji Wapya' : 'New Users',
            _buildRecentActivityList(
              isDark,
              primaryColor,
              textColor,
              subtextColor,
              isSwahili,
            ),
            isDark,
            cardColor,
            textColor,
            subtextColor,
          ),
          const SizedBox(height: 24),
          // Verification Queue Preview
          _buildSectionCard(
            Icons.verified_user_rounded,
            isSwahili ? 'Orodha ya Uthibitishaji' : 'Verification Queue',
            _buildVerificationQueuePreview(
              isDark,
              primaryColor,
              textColor,
              subtextColor,
              isSwahili,
            ),
            isDark,
            cardColor,
            textColor,
            subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    IconData icon,
    String title,
    Widget content,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    if (_recentUsers == null || _recentUsers!.isEmpty) {
      return Center(
        child: Text(
          isSwahili ? 'Hakuna shughuli za hivi karibuni' : 'No recent activity',
          style: GoogleFonts.poppins(color: subtextColor),
        ),
      );
    }

    return Column(
      children: _recentUsers!.take(5).map((user) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']?.toString() ??
                          user['firstName']?.toString() ??
                          'Unknown',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isSwahili ? 'Amejiandikwa' : 'Registered',
                      style: GoogleFonts.poppins(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimestamp(user['createdAt']?.toString() ?? ''),
                style: GoogleFonts.poppins(color: subtextColor, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours';
      } else {
        return '${difference.inDays} days';
      }
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildVerificationQueuePreview(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    if (_verificationQueue == null || _verificationQueue!.isEmpty) {
      return Center(
        child: Text(
          isSwahili
              ? 'Hakuna ombi la uthibitishaji'
              : 'No verification requests',
          style: GoogleFonts.poppins(color: subtextColor),
        ),
      );
    }

    return Column(
      children: _verificationQueue!.take(3).map((item) {
        final name =
            item['name']?.toString() ??
            item['fullName']?.toString() ??
            'Unknown';
        final email = item['email']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pending_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsersContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: isSwahili
                        ? 'Tafuta watumiaji...'
                        : 'Search users...',
                    prefixIcon: Icon(Icons.search, color: subtextColor),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF111614)
                        : const Color(0xFFF1F5F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111614)
                      : const Color(0xFFF1F5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _userFilter,
                    style: GoogleFonts.poppins(color: textColor),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(isSwahili ? 'Wote' : 'All'),
                      ),
                      DropdownMenuItem(
                        value: 'verified',
                        child: Text(isSwahili ? 'Walioidhinishwa' : 'Verified'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text(isSwahili ? 'Wanasubiri' : 'Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'banned',
                        child: Text(isSwahili ? 'Waliokataliwa' : 'Banned'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _userFilter = value ?? 'all');
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Users List
          if (_allUsers == null || _allUsers!.isEmpty)
            Center(
              child: Text(
                isSwahili ? 'Hakuna watumiaji' : 'No users found',
                style: GoogleFonts.poppins(color: subtextColor),
              ),
            )
          else
            ..._allUsers!.map((user) {
              return _buildUserCard(
                user,
                isDark,
                primaryColor,
                cardColor,
                textColor,
                subtextColor,
                isSwahili,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final userId = user['id']?.toString() ?? '';
    final name =
        user['name']?.toString() ?? user['firstName']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'normal';
    final isBanned = user['isBanned'] == true;
    final isVerified = user['isVerified'] == true;
    final phone = user['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isBanned
                      ? Colors.red.withValues(alpha: 0.1)
                      : isVerified
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isBanned
                      ? isSwahili
                            ? 'Imekataliwa'
                            : 'Banned'
                      : isVerified
                      ? isSwahili
                            ? 'Imeidhinishwa'
                            : 'Verified'
                      : isSwahili
                      ? 'Inasubiri'
                      : 'Pending',
                  style: GoogleFonts.poppins(
                    color: isBanned
                        ? Colors.red
                        : isVerified
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: role == 'admin'
                      ? Colors.purple.withValues(alpha: 0.1)
                      : role == 'landlord'
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: role == 'admin'
                        ? Colors.purple
                        : role == 'landlord'
                        ? Colors.blue
                        : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Actions
              IconButton(
                icon: Icon(Icons.visibility_rounded, color: primaryColor),
                onPressed: () => _showUserDetails(
                  user,
                  isDark,
                  primaryColor,
                  textColor,
                  subtextColor,
                  isSwahili,
                ),
                tooltip: isSwahili ? 'Angalia' : 'View',
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: primaryColor),
                onPressed: () => _editUser(
                  user,
                  isDark,
                  primaryColor,
                  textColor,
                  subtextColor,
                  isSwahili,
                ),
                tooltip: isSwahili ? 'Hariri' : 'Edit',
              ),
              if (isBanned)
                IconButton(
                  icon: Icon(Icons.block_rounded, color: Colors.green),
                  onPressed: () => _unbanUser(userId, isSwahili),
                  tooltip: isSwahili ? 'Ruisha Uban' : 'Unban',
                )
              else
                IconButton(
                  icon: Icon(Icons.block_rounded, color: Colors.red),
                  onPressed: () => _banUser(userId, isSwahili),
                  tooltip: isSwahili ? 'Ban' : 'Ban',
                ),
              IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _deleteUser(userId, isSwahili),
                tooltip: isSwahili ? 'Futa' : 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHousesContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: isSwahili
                        ? 'Tafuta nyumba...'
                        : 'Search houses...',
                    prefixIcon: Icon(Icons.search, color: subtextColor),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF111614)
                        : const Color(0xFFF1F5F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111614)
                      : const Color(0xFFF1F5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _houseFilter,
                    style: GoogleFonts.poppins(color: textColor),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(isSwahili ? 'Zote' : 'All'),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text(isSwahili ? 'Zinazofanya kazi' : 'Active'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text(
                          isSwahili ? 'Zisizofanya kazi' : 'Inactive',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _houseFilter = value ?? 'all');
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Houses List
          if (_houses == null || _houses!.isEmpty)
            Center(
              child: Text(
                isSwahili ? 'Hakuna nyumba' : 'No houses found',
                style: GoogleFonts.poppins(color: subtextColor),
              ),
            )
          else
            ..._houses!.map((house) {
              return _buildHouseCard(
                house,
                isDark,
                primaryColor,
                cardColor,
                textColor,
                subtextColor,
                isSwahili,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildHouseCard(
    Map<String, dynamic> house,
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final houseId = house['id']?.toString() ?? '';
    final title =
        house['brandName']?.toString() ??
        house['title']?.toString() ??
        'Unknown';
    final location =
        house['location']?.toString() ?? house['address']?.toString() ?? '';
    final region = house['region']?.toString() ?? '';
    final district = house['district']?.toString() ?? '';
    final ward = house['ward']?.toString() ?? '';
    final rent = house['rentPrice']?.toString() ?? '0';
    final type = house['type']?.toString() ?? '';
    final images = house['images'] as List<dynamic>?;
    final mainImage = images != null && images.isNotEmpty
        ? images[0].toString()
        : '';
    final isActive = house['isActive'] == true;
    final ownerName = house['ownerName']?.toString() ?? '';

    final fullLocation = location.isNotEmpty
        ? location
        : region.isNotEmpty
        ? '$region${district.isNotEmpty ? ', $district' : ''}${ward.isNotEmpty ? ', $ward' : ''}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // House Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: mainImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          mainImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.home_rounded,
                              color: primaryColor,
                              size: 32,
                            );
                          },
                        ),
                      )
                    : Icon(Icons.home_rounded, color: primaryColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullLocation,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          isSwahili ? 'TSh $rent' : 'TSh $rent',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        if (type.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                color: primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (ownerName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        isSwahili ? 'Mwenye: $ownerName' : 'Owner: $ownerName',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive
                      ? isSwahili
                            ? 'Inafanya kazi'
                            : 'Active'
                      : isSwahili
                      ? 'Hafanyi kazi'
                      : 'Inactive',
                  style: GoogleFonts.poppins(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.visibility_rounded, color: primaryColor),
                onPressed: () => _showHouseDetails(
                  house,
                  isDark,
                  primaryColor,
                  textColor,
                  subtextColor,
                  isSwahili,
                ),
                tooltip: isSwahili ? 'Angalia' : 'View',
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: primaryColor),
                onPressed: () => _editHouse(
                  house,
                  isDark,
                  primaryColor,
                  textColor,
                  subtextColor,
                  isSwahili,
                ),
                tooltip: isSwahili ? 'Hariri' : 'Edit',
              ),
              IconButton(
                icon: Icon(
                  Icons.toggle_on_rounded,
                  color: isActive ? Colors.red : Colors.green,
                ),
                onPressed: () =>
                    _toggleHouseStatus(houseId, !isActive, isSwahili),
                tooltip: isActive
                    ? isSwahili
                          ? 'Fungua'
                          : 'Deactivate'
                    : isSwahili
                    ? 'Washa'
                    : 'Activate',
              ),
              IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _deleteHouse(houseId, isSwahili),
                tooltip: isSwahili ? 'Futa' : 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  Icons.pending_rounded,
                  isSwahili ? 'Zinasubiri' : 'Pending',
                  '${_verificationQueue?.length ?? 0}',
                  isDark,
                  Colors.orange,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.verified_rounded,
                  isSwahili ? 'Zimeidhinishwa' : 'Verified',
                  '${_dashboardData?['verifiedCount'] ?? 0}',
                  isDark,
                  Colors.green,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.cancel_rounded,
                  isSwahili ? 'Zimekataliwa' : 'Rejected',
                  '${_dashboardData?['rejectedCount'] ?? 0}',
                  isDark,
                  Colors.red,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Verification Queue
          if (_verificationQueue == null || _verificationQueue!.isEmpty)
            Center(
              child: Text(
                isSwahili
                    ? 'Hakuna ombi la uthibitishaji'
                    : 'No verification requests',
                style: GoogleFonts.poppins(color: subtextColor),
              ),
            )
          else
            ..._verificationQueue!.map((verification) {
              return _buildVerificationCard(
                verification,
                isDark,
                primaryColor,
                cardColor,
                textColor,
                subtextColor,
                isSwahili,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(
    Map<String, dynamic> verification,
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final userId =
        verification['userId']?.toString() ??
        verification['id']?.toString() ??
        '';
    final name =
        verification['name']?.toString() ??
        verification['fullName']?.toString() ??
        'Unknown';
    final email = verification['email']?.toString() ?? '';
    final submittedAt =
        verification['submittedAt']?.toString() ??
        verification['createdAt']?.toString() ??
        '';
    final identityStatus =
        verification['identityStatus']?.toString() ?? 'pending';
    final propertyStatus =
        verification['propertyStatus']?.toString() ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: identityStatus == 'verified'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSwahili ? 'Utambulisho' : 'Identity',
                            style: GoogleFonts.poppins(
                              color: identityStatus == 'verified'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: propertyStatus == 'verified'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSwahili ? 'Mali' : 'Property',
                            style: GoogleFonts.poppins(
                              color: propertyStatus == 'verified'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (submittedAt.isNotEmpty)
                Text(
                  _formatTimestamp(submittedAt),
                  style: GoogleFonts.poppins(fontSize: 12, color: subtextColor),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDetails(
                    verification,
                    isDark,
                    primaryColor,
                    textColor,
                    subtextColor,
                    isSwahili,
                  ),
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(isSwahili ? 'Angalia Maelezo' : 'View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveVerification(userId, isSwahili),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(isSwahili ? 'Idhinishisha' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectVerification(userId, isSwahili),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(isSwahili ? 'Kataa' : 'Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Overview
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  Icons.trending_up_rounded,
                  isSwahili ? 'Watumiaji Wapya' : 'New Users',
                  '${_newRegistrations?.length ?? 0}',
                  isDark,
                  Colors.blue,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.home_work_rounded,
                  isSwahili ? 'Nyumba Mpya' : 'New Houses',
                  '${_dashboardData?['newHouses'] ?? 0}',
                  isDark,
                  Colors.green,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.verified_rounded,
                  isSwahili ? 'Uthibitishaji' : 'Verifications',
                  '${_dashboardData?['verifiedCount'] ?? 0}',
                  isDark,
                  Colors.purple,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // New Registrations List
          _buildSectionCard(
            Icons.person_add_rounded,
            isSwahili ? 'Watumiaji Wapya' : 'New Registrations',
            _buildNewRegistrationsList(
              isDark,
              primaryColor,
              textColor,
              subtextColor,
              isSwahili,
            ),
            isDark,
            cardColor,
            textColor,
            subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNewRegistrationsList(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    if (_newRegistrations == null || _newRegistrations!.isEmpty) {
      return Center(
        child: Text(
          isSwahili ? 'Hakuna usajili mpya' : 'No new registrations',
          style: GoogleFonts.poppins(color: subtextColor),
        ),
      );
    }

    return Column(
      children: _newRegistrations!.take(5).map((user) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']?.toString() ??
                          user['firstName']?.toString() ??
                          'Unknown',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user['email']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimestamp(user['createdAt']?.toString() ?? ''),
                style: GoogleFonts.poppins(color: subtextColor, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsContent(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_rounded, size: 64, color: subtextColor),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Mipangilio' : 'Settings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili ? 'Hali ya kazi...' : 'Coming soon...',
            style: GoogleFonts.poppins(color: subtextColor),
          ),
        ],
      ),
    );
  }

  // ==================== User Management Actions ====================

  Future<void> _showUserDetails(
    Map<String, dynamic> user,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) async {
    final userId = user['id']?.toString() ?? '';
    final details = await ApiService.getUserDetails(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Maelezo ya Mtumiaji' : 'User Details'),
        content: SingleChildScrollView(
          child: details != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      isSwahili ? 'Jina' : 'Name',
                      details['name']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Barua pepe' : 'Email',
                      details['email']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Namba ya simu' : 'Phone',
                      details['phone']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Jukumu' : 'Role',
                      details['role']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Imeidhinishwa' : 'Verified',
                      details['isVerified'] == true ? 'Yes' : 'No',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Imekataliwa' : 'Banned',
                      details['isBanned'] == true ? 'Yes' : 'No',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Imejiandikwa' : 'Registered',
                      details['createdAt']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                  ],
                )
              : Text(
                  isSwahili
                      ? 'Imeshindika kupata maelezo'
                      : 'Failed to load details',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Funga' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: subtextColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _editUser(
    Map<String, dynamic> user,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) async {
    final userId = user['id']?.toString() ?? '';
    final nameController = TextEditingController(
      text: user['name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: user['email']?.toString() ?? '',
    );
    final roleController = TextEditingController(
      text: user['role']?.toString() ?? 'normal',
    );

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Hariri Mtumiaji' : 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Jina' : 'Name',
              ),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Barua pepe' : 'Email',
              ),
            ),
            TextField(
              controller: roleController,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Jukumu' : 'Role',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'email': emailController.text,
                'role': roleController.text,
              });
            },
            child: Text(isSwahili ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await ApiService.updateUser(userId, result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa kuhariri'
                      : 'User updated successfully'
                : isSwahili
                ? 'Imeshindika kuhariri'
                : 'Failed to update user',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _banUser(String userId, bool isSwahili) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Ban Mtumiaji?' : 'Ban User?'),
        content: Text(
          isSwahili
              ? 'Una uhakika unataka kumban mtumiaji huyu?'
              : 'Are you sure you want to ban this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isSwahili ? 'Ban' : 'Ban'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.banUser(userId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa kuban'
                      : 'User banned successfully'
                : isSwahili
                ? 'Imeshindika kuban'
                : 'Failed to ban user',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _unbanUser(String userId, bool isSwahili) async {
    final success = await ApiService.unbanUser(userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? isSwahili
                    ? 'Imefanikiwa kuondoa ban'
                    : 'User unbanned successfully'
              : isSwahili
              ? 'Imeshindika kuondoa ban'
              : 'Failed to unban user',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadDashboardData();
    }
  }

  Future<void> _deleteUser(String userId, bool isSwahili) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Futa Mtumiaji?' : 'Delete User?'),
        content: Text(
          isSwahili
              ? 'Hatari! Hii hatowezi kuundoa. Una uhakika?'
              : 'Warning! This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteUser(userId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa kufuta'
                      : 'User deleted successfully'
                : isSwahili
                ? 'Imeshindika kufuta'
                : 'Failed to delete user',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  // ==================== House Management Actions ====================

  Future<void> _showHouseDetails(
    Map<String, dynamic> house,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) async {
    final houseId = house['id']?.toString() ?? '';
    final details = await ApiService.getHouseDetailsAdmin(houseId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Maelezo ya Nyumba' : 'House Details'),
        content: SingleChildScrollView(
          child: details != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      isSwahili ? 'Jina' : 'Name',
                      details['brandName']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Eneo' : 'Location',
                      details['location']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Kodi' : 'Rent',
                      details['rentPrice']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Aina' : 'Type',
                      details['type']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Inafanya kazi' : 'Active',
                      details['isActive'] == true ? 'Yes' : 'No',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Picha' : 'Images',
                      '${(details['images'] as List<dynamic>?)?.length ?? 0}',
                      textColor,
                      subtextColor,
                    ),
                  ],
                )
              : Text(
                  isSwahili
                      ? 'Imeshindika kupata maelezo'
                      : 'Failed to load details',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Funga' : 'Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _editHouse(
    Map<String, dynamic> house,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) async {
    final houseId = house['id']?.toString() ?? '';
    final titleController = TextEditingController(
      text: house['brandName']?.toString() ?? '',
    );
    final rentController = TextEditingController(
      text: house['rentPrice']?.toString() ?? '',
    );

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Hariri Nyumba' : 'Edit House'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Jina la Nyumba' : 'House Name',
              ),
            ),
            TextField(
              controller: rentController,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Kodi' : 'Rent',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'brandName': titleController.text,
                'rentPrice': rentController.text,
              });
            },
            child: Text(isSwahili ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await ApiService.updateAdminHouse(houseId, result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa kuhariri'
                      : 'House updated successfully'
                : isSwahili
                ? 'Imeshindika kuhariri'
                : 'Failed to update house',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _toggleHouseStatus(
    String houseId,
    bool newStatus,
    bool isSwahili,
  ) async {
    final success = await ApiService.updateAdminHouse(houseId, {
      'isActive': newStatus,
    });
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? isSwahili
                    ? 'Imefanikiwa kubadili status'
                    : 'House status updated successfully'
              : isSwahili
              ? 'Imeshindika kubadili status'
              : 'Failed to update house status',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadDashboardData();
    }
  }

  Future<void> _deleteHouse(String houseId, bool isSwahili) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Futa Nyumba?' : 'Delete House?'),
        content: Text(
          isSwahili
              ? 'Hatari! Hii hatowezi kuundoa. Una uhakika?'
              : 'Warning! This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteAdminHouse(houseId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa kufuta'
                      : 'House deleted successfully'
                : isSwahili
                ? 'Imeshindika kufuta'
                : 'Failed to delete house',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  // ==================== Verification Actions ====================

  Future<void> _showVerificationDetails(
    Map<String, dynamic> verification,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) async {
    final userId =
        verification['userId']?.toString() ??
        verification['id']?.toString() ??
        '';
    final details = await ApiService.getVerificationDetails(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Maelezo ya Uthibitishaji' : 'Verification Details',
        ),
        content: SingleChildScrollView(
          child: details != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      isSwahili ? 'Jina kamili' : 'Full Name',
                      details['fullName']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Barua pepe' : 'Email',
                      details['email']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Namba ya NIDA' : 'NIDA Number',
                      details['ninNumber']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Status ya utambulisho' : 'Identity Status',
                      details['identityStatus']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    _buildDetailRow(
                      isSwahili ? 'Status ya mali' : 'Property Status',
                      details['propertyStatus']?.toString() ?? 'N/A',
                      textColor,
                      subtextColor,
                    ),
                    const SizedBox(height: 16),
                    if (details['idPhoto'] != null)
                      _buildDocumentButton(
                        isSwahili ? 'Picha ya Kitambulisho' : 'ID Photo',
                        details['idPhoto'].toString(),
                        primaryColor,
                        isSwahili,
                      ),
                    if (details['selfie'] != null)
                      _buildDocumentButton(
                        isSwahili ? 'Selfie' : 'Selfie',
                        details['selfie'].toString(),
                        primaryColor,
                        isSwahili,
                      ),
                    if (details['idDocument'] != null)
                      _buildDocumentButton(
                        isSwahili ? 'Hati ya Kitambulisho' : 'ID Document',
                        details['idDocument'].toString(),
                        primaryColor,
                        isSwahili,
                      ),
                  ],
                )
              : Text(
                  isSwahili
                      ? 'Imeshindika kupata maelezo'
                      : 'Failed to load details',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Funga' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentButton(
    String label,
    String url,
    Color primaryColor,
    bool isSwahili,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(url),
        icon: const Icon(Icons.download_rounded),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _approveVerification(String userId, bool isSwahili) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Idhinishisha Uthibitishaji?' : 'Approve Verification?',
        ),
        content: Text(
          isSwahili
              ? 'Una uhakika unataka ku-idhinishisha uthibitishaji huu?'
              : 'Are you sure you want to approve this verification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(isSwahili ? 'Idhinishisha' : 'Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.approveVerification(userId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa ku-idhinishisha'
                      : 'Verification approved successfully'
                : isSwahili
                ? 'Imeshindika ku-idhinishisha'
                : 'Failed to approve verification',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _rejectVerification(String userId, bool isSwahili) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSwahili ? 'Kataa Uthibitishaji' : 'Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isSwahili
                    ? 'Sababu ya kukataa'
                    : 'Reason for rejection',
                hintText: isSwahili ? 'Andika sababu...' : 'Enter reason...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isSwahili ? 'Kataa' : 'Reject'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await ApiService.rejectVerification(userId, result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? isSwahili
                      ? 'Imefanikiwa kukataa'
                      : 'Verification rejected successfully'
                : isSwahili
                ? 'Imeshindika kukataa'
                : 'Failed to reject verification',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDashboardData();
      }
    }
  }
}
