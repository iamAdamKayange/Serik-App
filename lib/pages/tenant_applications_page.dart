import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/rental_application_model.dart';
import '../providers/theme_provider.dart';
import '../services/rental_application_service.dart';

class TenantApplicationsPage extends StatefulWidget {
  final int initialTabIndex;
  const TenantApplicationsPage({super.key, this.initialTabIndex = 0});

  @override
  State<TenantApplicationsPage> createState() => _TenantApplicationsPageState();
}

class _TenantApplicationsPageState extends State<TenantApplicationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'sw_TZ',
    symbol: 'TZS ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    RentalApplicationService.loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case ApplicationStatus.approved:
        return const Color(0xFF10B981); // Emerald
      case ApplicationStatus.depositPaid:
        return const Color(0xFF0EA5E9); // Ocean Sky
      case ApplicationStatus.activeLease:
        return const Color(0xFF2E7D32); // Primary Green
      case ApplicationStatus.rejected:
        return const Color(0xFFEF4444); // Rose Red
      case ApplicationStatus.completed:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.approved:
        return Icons.check_circle_rounded;
      case ApplicationStatus.depositPaid:
        return Icons.verified_rounded;
      case ApplicationStatus.activeLease:
        return Icons.home_work_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case ApplicationStatus.completed:
        return Icons.task_alt_rounded;
    }
  }

  void _showApplicationDetailsDialog(
    BuildContext context,
    RentalApplication app,
    bool isDark,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          app.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(app.status),
                            size: 14,
                            color: _getStatusColor(app.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            app.statusTitleSw,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _getStatusColor(app.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      app.id,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  app.houseTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: subtextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        app.location,
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tracking Stepper
                _buildTrackingTimeline(app, isDark, primaryColor),

                const SizedBox(height: 20),
                // Spec Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF282828)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF383838)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Kodi ya Mwezi',
                        _currencyFormat.format(app.monthlyRent),
                        textColor,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Deposit ya Nyumba',
                        _currencyFormat.format(app.depositAmount),
                        textColor,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Muda wa Mkataba',
                        'Miezi ${app.leaseMonths}',
                        textColor,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Tarehe ya Kuhamia',
                        DateFormat('dd MMMM yyyy').format(app.moveInDate),
                        textColor,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Idadi ya Wakazi',
                        'Watu ${app.occupantsCount}',
                        textColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Landlord Contact
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryColor,
                        child: Text(
                          app.ownerName.isNotEmpty
                              ? app.ownerName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.ownerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Mwenye Nyumba (Landlord)',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (app.ownerPhone.isNotEmpty) {
                            final uri = Uri.parse('tel:${app.ownerPhone}');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.call, size: 18),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (app.ownerPhone.isNotEmpty) {
                            final cleanPhone = app.ownerPhone.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final uri = Uri.parse(
                              'https://wa.me/$cleanPhone?text=Habari, nafuatilia maombi ya nyumba ${app.houseTitle}',
                            );
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.chat, size: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Actions according to status
                if (app.status == ApplicationStatus.approved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await RentalApplicationService.updateStatus(
                          app.id,
                          ApplicationStatus.depositPaid,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '✅ Malipo ya deposit yamekamilika! Mkataba wako umethibitishwa.',
                            ),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payment_rounded),
                      label: Text(
                        'Lipa Deposit (${_currencyFormat.format(app.depositAmount)})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                if (app.status == ApplicationStatus.depositPaid)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await RentalApplicationService.updateStatus(
                          app.id,
                          ApplicationStatus.activeLease,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎉 Hongera! Umeingia rasmi kwenye mkataba wa nyumba.',
                            ),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      },
                      icon: const Icon(Icons.key_rounded),
                      label: const Text(
                        'Thibitisha Kuingia Nyumbani (Move In)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Funga',
                      style: TextStyle(
                        color: subtextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackingTimeline(
    RentalApplication app,
    bool isDark,
    Color primaryColor,
  ) {
    final steps = [
      {'title': 'Maombi Yametumwa', 'sub': 'Yamepokewa'},
      {'title': 'Mapitio ya Landlord', 'sub': 'Mchakato wa uhakiki'},
      {'title': 'Malipo ya Deposit', 'sub': 'Kuhifadhi nyumba'},
      {'title': 'Kukabidhiwa Ufunguo', 'sub': 'Mkataba Uko Hai'},
    ];

    int activeIndex = app.timelineStep - 1;
    if (app.status == ApplicationStatus.rejected) activeIndex = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Mchakato wa Maombi (Live Timeline)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: List.generate(steps.length, (index) {
              final isPassed = index <= activeIndex;
              final isCurrent = index == activeIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPassed
                              ? primaryColor
                              : (isDark
                                  ? Colors.grey[800]
                                  : const Color(0xFFE2E8F0)),
                          border: Border.all(
                            color: isCurrent
                                ? primaryColor.withValues(alpha: 0.3)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: isPassed
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: isPassed && index < activeIndex
                              ? primaryColor
                              : (isDark
                                  ? Colors.grey[800]
                                  : const Color(0xFFCBD5E1)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[index]['title']!,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                              color: isPassed
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                  : Colors.grey[500],
                            ),
                          ),
                          Text(
                            steps[index]['sub']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  void _showReportMaintenanceDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Maji / Mabomba';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.build_circle_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ripoti Changamoto',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chagua Aina ya Tatizo:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: cardBg,
                      items: [
                        'Maji / Mabomba',
                        'Umeme / LUKU',
                        'Kuta / Rangi',
                        'Mlango / Kufuli',
                        'Usafi / Mazingira',
                        'Tatizo Lingine',
                      ].map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: TextStyle(fontSize: 13, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateModal(() => category = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Kichwa cha Taarifa:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Mf: Bomba la bafu linavuja maji',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Maelezo zaidi kwa Mwenye Nyumba:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Eleza kwa kifupi eneo na uharibifu...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ghairi'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Taarifa ya ukarabati imetumwa kwa Mwenye Nyumba.',
                        ),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  child: const Text('Tuma Taarifa'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home_work_rounded, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maombi & Kodi Yangu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Text(
                  'Fuatilia maombi na mikataba ya nyumba',
                  style: TextStyle(fontSize: 11, color: subtextColor),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF282828) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: subtextColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Maombi ya Nyumba'),
                Tab(text: 'Mkataba & Kodi Yangu'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationsList(isDark, primaryColor, cardBg, textColor, subtextColor),
          _buildActiveLeasesView(isDark, primaryColor, cardBg, textColor, subtextColor),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    return ValueListenableBuilder<List<RentalApplication>>(
      valueListenable: RentalApplicationService.applicationsNotifier,
      builder: (context, applications, _) {
        final pendingApps = applications
            .where((a) => a.status != ApplicationStatus.activeLease)
            .toList();

        if (pendingApps.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.note_alt_outlined,
                      size: 54,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Huna Maombi ya Nyumba kwa Sasa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tafuta nyumba inayokufaa na ubofye "Omba Kupangishwa" ili kutuma maombi moja kwa moja.',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingApps.length,
          itemBuilder: (context, index) {
            final app = pendingApps[index];
            final statusColor = _getStatusColor(app.status);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showApplicationDetailsDialog(
                  context,
                  app,
                  isDark,
                  primaryColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: app.houseImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: app.houseImage,
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                    ),
                                    errorWidget: (_, _, _) => Container(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      child: const Icon(Icons.home_rounded),
                                    ),
                                  )
                                : Container(
                                    width: 76,
                                    height: 76,
                                    color: primaryColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.home_work_rounded,
                                      color: primaryColor,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatusIcon(app.status),
                                            size: 12,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            app.statusTitleSw,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat(
                                        'dd MMM',
                                      ).format(app.appliedDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  app.houseTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_currencyFormat.format(app.monthlyRent)} / mwezi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF282828)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tarehe ya Kuhamia:',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(app.moveInDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _showApplicationDetailsDialog(
                                context,
                                app,
                                isDark,
                                primaryColor,
                              ),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text(
                                'Maelezo & Hatua',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          if (app.status == ApplicationStatus.approved) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () async {
                                  await RentalApplicationService.updateStatus(
                                    app.id,
                                    ApplicationStatus.depositPaid,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ Malipo ya deposit yamekamilika!',
                                      ),
                                      backgroundColor: Color(0xFF2E7D32),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text(
                                  'Lipa Deposit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveLeasesView(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    return ValueListenableBuilder<List<RentalApplication>>(
      valueListenable: RentalApplicationService.applicationsNotifier,
      builder: (context, applications, _) {
        final activeLeases = applications
            .where((a) => a.status == ApplicationStatus.activeLease)
            .toList();

        if (activeLeases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      size: 54,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bado Huna Nyumba Unayoishi Rasmi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Baada ya maombi yako kukubaliwa na kulipa deposit, nyumba yako itaonekana hapa ikiwa na huduma za malipo ya kodi na kuripoti ukarabati.',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final activeApp = activeLeases.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Lease Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)]
                        : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Mkataba Uko Hai (Active)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Siku 18 Zimebaki',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      activeApp.houseTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeApp.location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kodi ya Kila Mwezi',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(activeApp.monthlyRent),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B5E20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '💳 Malipo ya kodi ya mwezi yanafunguliwa...',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: const Text(
                            'Lipa Kodi',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Huduma za Mpangaji',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTenantActionTile(
                      icon: Icons.build_circle_rounded,
                      title: 'Ripoti Tatizo',
                      subtitle: 'Maji, Umeme, Ukarabati',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      cardBg: cardBg,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () => _showReportMaintenanceDialog(context, isDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTenantActionTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Risiti za Malipo',
                      subtitle: 'Historia ya Kodi',
                      color: const Color(0xFF0EA5E9),
                      isDark: isDark,
                      cardBg: cardBg,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '📑 Risiti zote za kodi zimehifadhiwa salama.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Landlord Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      child: Icon(Icons.person_rounded, color: primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeApp.ownerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Mwenye Nyumba (Landlord) • ${activeApp.ownerPhone}',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded),
                      color: primaryColor,
                      onPressed: () async {
                        if (activeApp.ownerPhone.isNotEmpty) {
                          final uri = Uri.parse('tel:${activeApp.ownerPhone}');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTenantActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: subtextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
