import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ModernAdminHomeScreen extends StatefulWidget {
  const ModernAdminHomeScreen({super.key});

  @override
  State<ModernAdminHomeScreen> createState() => _ModernAdminHomeScreenState();
}

class _ModernAdminHomeScreenState extends State<ModernAdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic>? _verificationQueue;
  List<dynamic>? _recentUsers;
  List<dynamic>? _houses;
  List<dynamic>? _allUsers;
  List<dynamic>? _newRegistrations;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getVerificationQueue(),
        ApiService.getRecentUsers(),
        ApiService.getAllHouses(),
        ApiService.getAllUsers(),
        ApiService.getNewRegistrations(),
      ]);

      if (!mounted) return;
      setState(() {
        _verificationQueue = results[0];
        _recentUsers = results[1];
        _houses = results[2];
        _allUsers = results[3];
        _newRegistrations = results[4];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    final primaryColor = const Color(0xFF0F8B61);
    final backgroundColor = isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0D1117);
    final subtextColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76);
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Modern Professional AppBar
          _buildModernAppBar(authProvider, isDark, primaryColor, textColor, subtextColor, borderColor),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState(isDark, primaryColor)
                : _buildSelectedContent(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor),
          ),
          
          // Bottom Navigation
          _buildModernBottomNavigation(isDark, primaryColor, textColor, subtextColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(
    AuthProvider authProvider,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Logo/Brand
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF0F8B61),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SERK Admin',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Platform Management',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile section
            Row(
              children: [
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: subtextColor,
                  onPressed: _loadDashboardData,
                  tooltip: 'Refresh',
                  iconSize: 20,
                ),
                
                // User avatar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: primaryColor.withValues(alpha: 0.2),
                        backgroundImage: authProvider.avatarUrl != null
                            ? CachedNetworkImageProvider(authProvider.avatarUrl!)
                            : null,
                        child: authProvider.avatarUrl == null
                            ? Text(
                                authProvider.userName?.substring(0, 1).toUpperCase() ?? 'A',
                                style: GoogleFonts.poppins(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            authProvider.userName ?? 'Admin',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Admin',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Logout button
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  color: Colors.red,
                  onPressed: () => _showLogoutDialog(),
                  tooltip: 'Logout',
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Inapakua data...',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
      case 1:
        return _buildUsersTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
      case 2:
        return _buildHousesTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
      case 3:
        return _buildVerificationsTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
      case 4:
        return _buildSecurityTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
      default:
        return _buildDashboardTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
    }
  }

  Widget _buildDashboardTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards Row
          Row(
            children: [
              Expanded(
                child: _buildModernKPICard(
                  Icons.people_outline,
                  _allUsers?.length.toString() ?? '0',
                  'Watumiaji',
                  isDark,
                  cardColor,
                  textColor,
                  subtextColor,
                  primaryColor,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernKPICard(
                  Icons.home_outlined,
                  _houses?.length.toString() ?? '0',
                  'Nyumba',
                  isDark,
                  cardColor,
                  textColor,
                  subtextColor,
                  primaryColor,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernKPICard(
                  Icons.verified_user_outlined,
                  _verificationQueue?.length.toString() ?? '0',
                  'Uthibitisho',
                  isDark,
                  cardColor,
                  textColor,
                  subtextColor,
                  primaryColor,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernKPICard(
                  Icons.person_add_outlined,
                  _newRegistrations?.length.toString() ?? '0',
                  'Wapya',
                  isDark,
                  cardColor,
                  textColor,
                  subtextColor,
                  primaryColor,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Quick Actions
          _buildSectionHeader('Haraka Zilizopo', Icons.flash_on, isDark, textColor, subtextColor),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  Icons.add_circle_outline,
                  'Ongeza Nyumba',
                  isDark,
                  cardColor,
                  primaryColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  Icons.people_outline,
                  'Watumiaji',
                  isDark,
                  cardColor,
                  primaryColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  Icons.verified_user,
                  'Uthibitisho',
                  isDark,
                  cardColor,
                  primaryColor,
                  textColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recent Activity Section
          _buildSectionHeader('Shughuli za Hivi Karibuni', Icons.timeline, isDark, textColor, subtextColor),
          const SizedBox(height: 12),
          
          // Recent Users
          _buildRecentUsersSection(isDark, cardColor, textColor, subtextColor, borderColor),
          const SizedBox(height: 16),
          
          // Recent Houses
          _buildRecentHousesSection(isDark, cardColor, textColor, subtextColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildModernKPICard(
    IconData icon,
    String value,
    String label,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, Color textColor, Color subtextColor) {
    return Row(
      children: [
        Icon(icon, color: textColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersSection(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final recentUsers = _recentUsers?.take(5).toList() ?? [];
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Watumiaji wa Hivi Karibuni',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                'Ona Zote',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF0F8B61),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentUsers.map((user) => _buildUserListItem(user, isDark, textColor, subtextColor)),
        ],
      ),
    );
  }

  Widget _buildUserListItem(dynamic user, bool isDark, Color textColor, Color subtextColor) {
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'normal';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF0F8B61).withValues(alpha: 0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F8B61),
                fontWeight: FontWeight.w600,
                fontSize: 12,
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
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: role == 'admin' 
                  ? Colors.red.withValues(alpha: 0.1)
                  : role == 'landlord'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: role == 'admin' 
                    ? Colors.red
                    : role == 'landlord'
                        ? Colors.green
                        : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHousesSection(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final recentHouses = _houses?.take(5).toList() ?? [];
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nyumba za Hivi Karibuni',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                'Ona Zote',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF0F8B61),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentHouses.map((house) => _buildHouseListItem(house, isDark, textColor, subtextColor)),
        ],
      ),
    );
  }

  Widget _buildHouseListItem(dynamic house, bool isDark, Color textColor, Color subtextColor) {
    final title = house['title']?.toString() ?? house['brandName']?.toString() ?? 'Unknown';
    final location = house['location']?.toString() ?? '';
    final price = house['price']?.toString() ?? house['rent']?.toString() ?? '0';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F8B61).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.home_outlined, color: Color(0xFF0F8B61), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  location,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'TSh $price',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F8B61),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: subtextColor),
          const SizedBox(height: 16),
          Text(
            'Watumiaji',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tab la Watumiaji inakuja hivi karibuni',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousesTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 48, color: subtextColor),
          const SizedBox(height: 16),
          Text(
            'Nyumba',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tab la Nyumba inakuja hivi karibuni',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 48, color: subtextColor),
          const SizedBox(height: 16),
          Text(
            'Uthibitisho',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tab la Uthibitisho inakuja hivi karibuni',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 48, color: subtextColor),
          const SizedBox(height: 16),
          Text(
            'Usalama',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tab la Usalama inakuja hivi karibuni',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNavigation(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard', 0, isDark, primaryColor, textColor, subtextColor),
          _buildNavItem(Icons.people_outline, 'Watumiaji', 1, isDark, primaryColor, textColor, subtextColor),
          _buildNavItem(Icons.home_outlined, 'Nyumba', 2, isDark, primaryColor, textColor, subtextColor),
          _buildNavItem(Icons.verified_user, 'Uthibitisho', 3, isDark, primaryColor, textColor, subtextColor),
          _buildNavItem(Icons.security, 'Usalama', 4, isDark, primaryColor, textColor, subtextColor),
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
    
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : subtextColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ondoka'),
        content: const Text('Unataka kuondoka akaunti yako ya admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Ndiyo'),
          ),
        ],
      ),
    );
  }
}
