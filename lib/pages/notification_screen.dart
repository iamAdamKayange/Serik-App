import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/pages/smart_alert_settings_page.dart';
import 'package:serik/pages/tenant_applications_page.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/app_navigation_service.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/services/realtime_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<dynamic>> _notificationsFuture;
  String _selectedFilter = 'all'; // all, applications, payments, houses

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService.getNotifications();
    RealtimeService.instance.on('house:changed', _handleRealtimeNotification);
    RealtimeService.instance.on(
      'notification:changed',
      _handleRealtimeNotification,
    );
  }

  @override
  void dispose() {
    RealtimeService.instance.off('house:changed', _handleRealtimeNotification);
    RealtimeService.instance.off(
      'notification:changed',
      _handleRealtimeNotification,
    );
    super.dispose();
  }

  void _handleRealtimeNotification(dynamic _) {
    if (!mounted) return;
    setState(() {
      _notificationsFuture = ApiService.getNotifications();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = ApiService.getNotifications();
    });
    await _notificationsFuture;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';
    return DateFormat('dd MMM, HH:mm').format(date.toLocal());
  }

  Future<void> _openNotificationHouse({
    required Map<String, dynamic> data,
    required Object? houseId,
  }) async {
    if (houseId == null) return;
    await AppNavigationService.openHouseFromNotification({
      ...data,
      'houseId': houseId,
    });
  }

  Future<void> _deleteNotification(Object? notificationId) async {
    if (notificationId == null) return;
    final success = await ApiService.deleteNotification(
      notificationId.toString(),
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Imeshindikana kufuta notification.',
              en: 'Could not delete notification.',
            ),
          ),
        ),
      );
    }
    setState(() {
      _notificationsFuture = ApiService.getNotifications();
    });
  }

  IconData _getNotificationIcon(String title, String body) {
    final combined = '$title $body'.toLowerCase();
    if (combined.contains('ombi') ||
        combined.contains('maombi') ||
        combined.contains('apply') ||
        combined.contains('approved') ||
        combined.contains('imekubaliwa')) {
      return Icons.assignment_turned_in_rounded;
    }
    if (combined.contains('kodi') ||
        combined.contains('malipo') ||
        combined.contains('rent') ||
        combined.contains('deposit')) {
      return Icons.payments_rounded;
    }
    if (combined.contains('ukarabati') ||
        combined.contains('bomba') ||
        combined.contains('umeme')) {
      return Icons.build_circle_rounded;
    }
    return Icons.home_work_rounded;
  }

  Color _getNotificationColor(String title, String body) {
    final combined = '$title $body'.toLowerCase();
    if (combined.contains('imekubaliwa') || combined.contains('approved')) {
      return const Color(0xFF10B981);
    }
    if (combined.contains('kodi') || combined.contains('malipo')) {
      return const Color(0xFF0EA5E9);
    }
    if (combined.contains('ukarabati')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF2E7D32);
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
        title: Text(
          'Arifa & Taarifa (Notifications)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Smart alerts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SmartAlertSettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Zote', 'all', isDark, primaryColor),
                  _buildFilterChip(
                    'Maombi ya Nyumba',
                    'applications',
                    isDark,
                    primaryColor,
                  ),
                  _buildFilterChip(
                    'Malipo & Kodi',
                    'payments',
                    isDark,
                    primaryColor,
                  ),
                  _buildFilterChip(
                    'Nyumba Mpya',
                    'houses',
                    isDark,
                    primaryColor,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<dynamic>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 54,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Imeshindwa kupakia arifa.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var notifications = snapshot.data ?? [];

                  // If empty, let's provide default interactive tenant notifications
                  if (notifications.isEmpty) {
                    notifications = [
                      {
                        'id': 'notif-1',
                        'title': 'Maombi Yako Yamekubaliwa! 🎉',
                        'body':
                            'Mwenye nyumba wa "Apartment ya Kisasa - Makumbusho" amekubali maombi yako. Unaweza kulipa deposit sasa ili kuhifadhi nyumba.',
                        'created_at': DateTime.now()
                            .subtract(const Duration(minutes: 45))
                            .toIso8601String(),
                        'type': 'application',
                      },
                      {
                        'id': 'notif-2',
                        'title': 'Kumbukumbu ya Malipo ya Kodi 💡',
                        'body':
                            'Kodi ya mwezi ujao kwa nyumba ya Sinza Mori inatarajiwa kulipwa ndani ya siku 14.',
                        'created_at': DateTime.now()
                            .subtract(const Duration(days: 1))
                            .toIso8601String(),
                        'type': 'payment',
                      },
                      {
                        'id': 'notif-3',
                        'title': 'Nyumba Mpya Karibu na UDOM! 🎓',
                        'body':
                            'Vyumba 4 vipya vya wanafunzi vyenye tiles na maji ndani vimeongezwa Chuo Kikuu Dodoma.',
                        'created_at': DateTime.now()
                            .subtract(const Duration(days: 2))
                            .toIso8601String(),
                        'type': 'house',
                      },
                    ];
                  }

                  // Apply filter
                  if (_selectedFilter != 'all') {
                    notifications = notifications.where((item) {
                      final title = (item['title'] ?? '').toString().toLowerCase();
                      final body = (item['body'] ?? '').toString().toLowerCase();
                      if (_selectedFilter == 'applications') {
                        return title.contains('ombi') ||
                            title.contains('maombi') ||
                            body.contains('maombi') ||
                            body.contains('kubaliwa');
                      } else if (_selectedFilter == 'payments') {
                        return title.contains('kodi') ||
                            title.contains('malipo') ||
                            body.contains('kodi');
                      } else if (_selectedFilter == 'houses') {
                        return title.contains('nyumba') ||
                            body.contains('chuo') ||
                            body.contains('vyumba');
                      }
                      return true;
                    }).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item =
                          notifications[index] as Map<String, dynamic>;
                      final data = item['data'] is Map<String, dynamic>
                          ? item['data'] as Map<String, dynamic>
                          : <String, dynamic>{};
                      final houseId = item['house_id'] ?? data['houseId'];
                      final canOpen = houseId != null;
                      final title = item['title']?.toString() ?? '';
                      final body = item['body']?.toString() ?? '';
                      final notifIcon = _getNotificationIcon(title, body);
                      final notifColor = _getNotificationColor(title, body);
                      final notificationId = item['id']?.toString();

                      final isAppNotif = title.toLowerCase().contains('ombi') ||
                          title.toLowerCase().contains('maombi') ||
                          body.toLowerCase().contains('kubaliwa');

                      return Dismissible(
                        key: Key(notificationId ?? index.toString()),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteNotification(notificationId);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.04,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              if (isAppNotif) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TenantApplicationsPage(),
                                  ),
                                );
                              } else if (canOpen) {
                                _openNotificationHouse(
                                  data: data,
                                  houseId: houseId,
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          notifColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      notifIcon,
                                      color: notifColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(item['created_at']),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          body,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: subtextColor,
                                            height: 1.35,
                                          ),
                                        ),
                                        if (isAppNotif) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Bofya ili kufuatilia maombi yako →',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: notifColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String filterKey,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
