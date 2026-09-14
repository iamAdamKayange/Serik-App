import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/auth_provider.dart';
// ignore: unused_import
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:serik/widgets/loading_states.dart';
import 'package:serik/widgets/pull_to_refresh.dart';
import 'package:serik/pages/admin_house_details_page.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic>? _verificationQueue;
  List<dynamic>? _recentUsers;
  List<dynamic>? _houses;
  List<dynamic>? _allUsers;
  List<dynamic>? _newRegistrations;
  String _userSearchQuery = '';
  String _houseSearchQuery = '';

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
    final l10n = AppLocalizations.of(context);
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
          // Professional Admin Header (No back button - this is root)
          _buildAdminHeader(authProvider, l10n, isDark, primaryColor, textColor, subtextColor, borderColor),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? LoadingState(
                    message: l10n.tr('Inapakia data ya dashboard...', en: 'Loading dashboard data...'),
                    variant: LoadingVariant.circular,
                  )
                : CustomPullToRefresh(
                    onRefresh: _loadDashboardData,
                    child: _buildSelectedContent(l10n, isDark, cardColor, textColor, subtextColor, borderColor, primaryColor),
                  ),
          ),
          
          // Bottom Navigation
          _buildBottomNavigation(isDark, primaryColor, textColor, subtextColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(
    AuthProvider authProvider,
    AppLocalizations l10n,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Color(0xFF0F8B61),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SERK Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  l10n.tr('Dashboard ya Usimamizi wa Jukwaa', en: 'Platform Management Dashboard'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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
                tooltip: l10n.tr('Refresh Data', en: 'Refresh Data'),
              ),
              
              // User avatar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
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
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userName ?? 'Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Administrator',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: Colors.red,
                onPressed: () => _showLogoutDialog(),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(
    AppLocalizations l10n,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n);
      case 1:
        return _buildUsersTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n);
      case 2:
        return _buildHousesTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n);
      case 3:
        return _buildVerificationsTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n);
      default:
        return _buildDashboardTab(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n);
    }
  }

  Widget _buildDashboardTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards Row
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  Icons.people_outline,
                  _allUsers?.length.toString() ?? '0',
                  l10n.tr('Watumiaji Jumla', en: 'Total Users'),
                  isDark,
                  cardColor,
                  textColor,
                  subtextColor,
                  primaryColor,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.home_outlined,
                  _houses?.length.toString() ?? '0',
                  l10n.tr('Nyumba Jumla', en: 'Total Houses'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  Icons.verified_user_outlined,
                  _verificationQueue?.length.toString() ?? '0',
                  l10n.tr('Uthibitishaji Zinasubiri', en: 'Pending Verifications'),
                  isDark,
                  cardColor,
                  textColor,
                  subtextColor,
                  primaryColor,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  Icons.person_add_outlined,
                  _newRegistrations?.length.toString() ?? '0',
                  l10n.tr('Usajili Mpya', en: 'New Registrations'),
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
          
          const SizedBox(height: 24),

          // Recent Activity Section
          _buildSectionHeader(l10n.tr('Shughuli za Hivi Karibuni', en: 'Recent Activity'), Icons.timeline, isDark, textColor, subtextColor, l10n),
          const SizedBox(height: 16),
          
          // Recent Users
          _buildRecentUsersSection(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
          const SizedBox(height: 24),

          // Recent Houses
          _buildRecentHousesSection(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
        ],
      ),
    );
  }

  Widget _buildKPICard(
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, Color textColor, Color subtextColor, AppLocalizations l10n) {
    return Row(
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
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
    AppLocalizations l10n,
  ) {
    final recentUsers = _recentUsers?.take(5).toList() ?? [];
    
    if (recentUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const EmptyState(
          title: 'No recent users',
          subtitle: 'New user registrations will appear here',
          icon: Icons.people_outline,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tr('Watumiaji wa Hivi Karibuni', en: 'Recent Users'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                l10n.tr('Ona Zote', en: 'View All'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF0F8B61),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF0F8B61).withValues(alpha: 0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F8B61),
                fontWeight: FontWeight.w600,
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: role == 'admin' 
                  ? Colors.red.withValues(alpha: 0.1)
                  : role == 'landlord'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
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
    AppLocalizations l10n,
  ) {
    final recentHouses = _houses?.take(5).toList() ?? [];
    
    if (recentHouses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const EmptyState(
          title: 'No recent houses',
          subtitle: 'New property listings will appear here',
          icon: Icons.home_outlined,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tr('Nyumba za Hivi Karibini', en: 'Recent Houses'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                l10n.tr('Ona Zote', en: 'View All'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF0F8B61),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentHouses.map((house) => _buildHouseListItem(house, isDark, textColor, subtextColor)),
        ],
      ),
    );
  }

  Widget _buildHouseListItem(dynamic house, bool isDark, Color textColor, Color subtextColor) {
    final title = house['title']?.toString() ?? house['brandName']?.toString() ?? 'Unknown';
    final location = house['location']?.toString() ?? '';
    final price = house['price']?.toString() ?? house['rent']?.toString() ?? '0';
    final houseId = house['id']?.toString();

    return InkWell(
      onTap: houseId != null ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminHouseDetailsPage(houseId: houseId),
          ),
        );
      } : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F8B61).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home_outlined, color: Color(0xFF0F8B61)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'TZS $price',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F8B61),
              ),
            ),
          ],
        ),
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
    AppLocalizations l10n,
  ) {
    final filteredUsers = _allUsers?.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      return name.contains(_userSearchQuery.toLowerCase()) || 
             email.contains(_userSearchQuery.toLowerCase());
    }).toList() ?? [];

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: subtextColor),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _userSearchQuery = value),
                    decoration: InputDecoration(
                      hintText: l10n.tr('Tafuta watumiaji...', en: 'Search users...'),
                      hintStyle: GoogleFonts.poppins(color: subtextColor),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.poppins(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Users list
        Expanded(
          child: filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    l10n.tr('Hakuna watumiaji waliopatikana', en: 'No users found'),
                    style: GoogleFonts.poppins(color: subtextColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    return _buildUserListItem(filteredUsers[index], isDark, textColor, subtextColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHousesTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    final filteredHouses = _houses?.where((house) {
      final title = house['title']?.toString().toLowerCase() ?? house['brandName']?.toString().toLowerCase() ?? '';
      final location = house['location']?.toString().toLowerCase() ?? '';
      return title.contains(_houseSearchQuery.toLowerCase()) || 
             location.contains(_houseSearchQuery.toLowerCase());
    }).toList() ?? [];

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: subtextColor),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _houseSearchQuery = value),
                    decoration: InputDecoration(
                      hintText: l10n.tr('Tafuta nyumba...', en: 'Search houses...'),
                      hintStyle: GoogleFonts.poppins(color: subtextColor),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.poppins(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Houses list
        Expanded(
          child: filteredHouses.isEmpty
              ? Center(
                  child: Text(
                    l10n.tr('Hakuna nyumba zilizopatikana', en: 'No houses found'),
                    style: GoogleFonts.poppins(color: subtextColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredHouses.length,
                  itemBuilder: (context, index) {
                    return _buildHouseListItem(filteredHouses[index], isDark, textColor, subtextColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVerificationsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return _verificationQueue == null || _verificationQueue!.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 64, color: subtextColor),
                const SizedBox(height: 16),
                Text(
                  l10n.tr('Hakuna uthibitishaji unazosubiri', en: 'No pending verifications'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _verificationQueue!.length,
            itemBuilder: (context, index) {
              return _buildVerificationCard(_verificationQueue![index], isDark, cardColor, textColor, subtextColor, borderColor, primaryColor);
            },
          );
  }

  Widget _buildVerificationCard(
    Map<String, dynamic> request,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    final id = request['id']?.toString() ?? '';
    final fullName = request['full_name']?.toString() ?? 'Unknown';
    final ninNumber = request['nin_number']?.toString() ?? 'Not provided';
    final status = request['status']?.toString() ?? 'pending';
    final propertyVerification = request['property_verification'] as Map<String, dynamic>?;
    
    // Parse photo URLs
    String? idPhotoUrl;
    String? selfiePhotoUrl;
    
    try {
      if (request['id_photo_url'] != null) {
        final idPhotoJson = request['id_photo_url'] is String 
            ? jsonDecode(request['id_photo_url']) 
            : request['id_photo_url'];
        idPhotoUrl = idPhotoJson['url']?.toString();
      }
      if (request['selfie_photo_url'] != null) {
        final selfieJson = request['selfie_photo_url'] is String 
            ? jsonDecode(request['selfie_photo_url']) 
            : request['selfie_photo_url'];
        selfiePhotoUrl = selfieJson['url']?.toString();
      }
    } catch (e) {
      debugPrint('Error parsing photo URLs: $e');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending' ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'NIN: $ninNumber',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'pending' 
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: status == 'pending' ? const Color(0xFFF59E0B) : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Photos row
          Row(
            children: [
              if (idPhotoUrl != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: idPhotoUrl,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: primaryColor.withValues(alpha: 0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        color: primaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.credit_card, color: Color(0xFF0F8B61))),
                  ),
                ),
              const SizedBox(width: 12),
              if (selfiePhotoUrl != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: selfiePhotoUrl,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: primaryColor.withValues(alpha: 0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        color: primaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.face, color: Color(0xFF0F8B61))),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Property verification section (if exists)
          if (propertyVerification != null) ...[
            Container(
              height: 1,
              color: borderColor,
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),
            Text(
              'Property Documents',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (propertyVerification['address'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFF0F8B61)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            propertyVerification['address'].toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (propertyVerification['property_photos'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library, size: 16, color: Color(0xFF0F8B61)),
                          const SizedBox(width: 8),
                          Text(
                            '${propertyVerification['property_photos'].length} photos',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewVerificationDetails(id),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (status == 'pending')
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approveVerification(id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              if (status == 'pending')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectVerification(id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.dashboard_outlined,
                'Dashboard',
                isDark,
                primaryColor,
                textColor,
                subtextColor,
              ),
              _buildNavItem(
                1,
                Icons.people_outline,
                'Users',
                isDark,
                primaryColor,
                textColor,
                subtextColor,
              ),
              _buildNavItem(
                2,
                Icons.home_outlined,
                'Houses',
                isDark,
                primaryColor,
                textColor,
                subtextColor,
              ),
              _buildNavItem(
                3,
                Icons.verified_user_outlined,
                'Verifications',
                isDark,
                primaryColor,
                textColor,
                subtextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : subtextColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? primaryColor : subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewVerificationDetails(String verificationId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('View verification: $verificationId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error viewing verification')),
      );
    }
  }

  Future<void> _approveVerification(String verificationId) async {
    try {
      final success = await ApiService.approveVerification(verificationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Verification approved' : 'Failed to approve'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error approving verification')),
      );
    }
  }

  Future<void> _rejectVerification(String verificationId) async {
    try {
      final success = await ApiService.rejectVerification(verificationId, 'Rejected by admin');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Verification rejected' : 'Failed to reject'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
      if (success) _loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error rejecting verification')),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }
}
