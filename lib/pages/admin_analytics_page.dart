import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/services/api_services.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _kpiData = [];
  List<dynamic> _userGrowth = [];
  List<dynamic> _revenueTrends = [];
  Map<String, dynamic> _recentActivity = const {
    'users': <dynamic>[],
    'houses': <dynamic>[],
    'verifications': <dynamic>[],
  };

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAdminStatistics(),
        ApiService.getAdminKpiData(),
        ApiService.getUserGrowth(),
        ApiService.getRevenueTrends(),
        ApiService.getRecentActivity(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>?;
        _kpiData = results[1] as List<dynamic>;
        _userGrowth = results[2] as List<dynamic>;
        _revenueTrends = results[3] as List<dynamic>;
        _recentActivity = results[4] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0D1110)
        : const Color(0xFFF4F8F6);
    final card = isDark ? const Color(0xFF171C1A) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF10211B);
    final subtext = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primary = const Color(0xFF0F8B61);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        title: Text(
          'Admin Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: text),
        ),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: Icon(Icons.refresh_rounded, color: primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroCard(card, text, subtext, primary),
                  const SizedBox(height: 16),
                  _buildStatGrid(card, text, subtext, primary),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'KPI Highlights',
                    cardColor: card,
                    textColor: text,
                    subtextColor: subtext,
                    child: Column(
                      children: _kpiData
                          .map(
                            (item) => _buildKpiRow(
                              item as Map<String, dynamic>,
                              text,
                              subtext,
                              primary,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'User Growth',
                    cardColor: card,
                    textColor: text,
                    subtextColor: subtext,
                    child: _buildGrowthChart(text, subtext, primary),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Revenue Trends',
                    cardColor: card,
                    textColor: text,
                    subtextColor: subtext,
                    child: _buildRevenueChart(text, subtext, primary),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Recent Activity',
                    cardColor: card,
                    textColor: text,
                    subtextColor: subtext,
                    child: _buildActivityTimeline(text, subtext, primary),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard(Color card, Color text, Color subtext, Color primary) {
    final totalUsers = _stats?['totalUsers']?.toString() ?? '0';
    final totalHouses = _stats?['totalHouses']?.toString() ?? '0';
    final pending = _stats?['pendingVerifications']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform pulse',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Users: $totalUsers  •  Houses: $totalHouses  •  Pending checks: $pending',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(Color card, Color text, Color subtext, Color primary) {
    final items = [
      (
        'Users',
        _stats?['totalUsers']?.toString() ?? '0',
        Icons.people_rounded,
        const Color(0xFF3B82F6),
      ),
      (
        'Houses',
        _stats?['totalHouses']?.toString() ?? '0',
        Icons.home_rounded,
        const Color(0xFF10B981),
      ),
      (
        'Pending',
        _stats?['pendingVerifications']?.toString() ?? '0',
        Icons.pending_actions_rounded,
        const Color(0xFFF59E0B),
      ),
      (
        'Active',
        _stats?['activeListings']?.toString() ?? '0',
        Icons.verified_rounded,
        const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items
          .map(
            (item) => _buildMetricCard(
              item.$1,
              item.$2,
              item.$3,
              item.$4,
              card,
              text,
              subtext,
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color accent,
    Color card,
    Color text,
    Color subtext,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: subtext)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    Map<String, dynamic> item,
    Color text,
    Color subtext,
    Color primary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label']?.toString() ?? 'Metric',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['sub']?.toString() ?? '',
                  style: GoogleFonts.poppins(fontSize: 11, color: subtext),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['value']?.toString() ?? '0',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              Text(
                item['trend']?.toString() ?? '',
                style: GoogleFonts.poppins(fontSize: 11, color: primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(Color text, Color subtext, Color primary) {
    final rows = _userGrowth.map((entry) {
      final data = Map<String, dynamic>.from(entry as Map);
      return (
        data['date']?.toString() ?? '',
        // FIX: Convert num to double using .toDouble()
        (data['tenants'] as num?)?.toDouble() ?? 0.0,
        (data['landlords'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    if (rows.isEmpty) {
      return Text(
        'No growth data available',
        style: GoogleFonts.poppins(color: subtext),
      );
    }

    final maxValue = math.max(
      1.0,
      rows.fold<double>(
        0,
        (max, row) => math.max(max, math.max(row.$2, row.$3)),
      ),
    );

    return Column(
      children: rows
          .take(7)
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.$1,
                    style: GoogleFonts.poppins(fontSize: 11, color: subtext),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniBar(
                          'Tenants',
                          row.$2,
                          maxValue,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniBar(
                          'Landlords',
                          row.$3,
                          maxValue,
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMiniBar(
    String label,
    double value,
    double maxValue,
    Color color,
  ) {
    final width = (value / maxValue).clamp(0.05, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${value.toInt()}',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: width,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(Color text, Color subtext, Color primary) {
    final rows = _revenueTrends.map((entry) {
      final data = Map<String, dynamic>.from(entry as Map);
      return (
        data['month']?.toString() ?? '',
        // FIX: Convert num to double using .toDouble()
        (data['amount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    if (rows.isEmpty) {
      return Text(
        'No revenue data available',
        style: GoogleFonts.poppins(color: subtext),
      );
    }

    final maxValue = math.max(
      1.0,
      rows.fold<double>(0, (max, row) => math.max(max, row.$2)),
    );

    return Column(
      children: rows
          .take(6)
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      row.$1.substring(0, math.min(7, row.$1.length)),
                      style: GoogleFonts.poppins(fontSize: 11, color: subtext),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (row.$2 / maxValue).clamp(0.05, 1.0),
                        minHeight: 12,
                        backgroundColor: primary.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 92,
                    child: Text(
                      'TZS ${(row.$2 / 1000000).toStringAsFixed(1)}M',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 11, color: text),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActivityTimeline(Color text, Color subtext, Color primary) {
    final users = List<dynamic>.from(_recentActivity['users'] ?? const []);
    final houses = List<dynamic>.from(_recentActivity['houses'] ?? const []);
    final verifications = List<dynamic>.from(
      _recentActivity['verifications'] ?? const [],
    );

    final items = <Map<String, dynamic>>[
      ...users.map(
        (item) => {
          'title': '${item['name'] ?? 'User'} joined',
          'subtitle': item['email']?.toString() ?? '',
          'icon': Icons.person_rounded,
        },
      ),
      ...houses.map(
        (item) => {
          'title': '${item['title'] ?? 'House'} listed',
          'subtitle': item['location']?.toString() ?? '',
          'icon': Icons.home_rounded,
        },
      ),
      ...verifications.map((item) {
        final verification = Map<String, dynamic>.from(item as Map);
        final user = verification['user'] is Map
            ? Map<String, dynamic>.from(verification['user'] as Map)
            : <String, dynamic>{};
        return {
          'title': 'Verification ${verification['status'] ?? 'pending'}',
          'subtitle': user['name']?.toString() ?? '',
          'icon': Icons.verified_user_rounded,
        };
      }),
    ];

    if (items.isEmpty) {
      return Text(
        'No recent activity yet',
        style: GoogleFonts.poppins(color: subtext),
      );
    }

    return Column(
      children: items
          .take(10)
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                        Text(
                          item['subtitle']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
