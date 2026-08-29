import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/pages/smart_alert_settings_page.dart';
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
  String _selectedFilter = 'all'; // all, houses

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

  Future<void> _openNotificationItem(Map<String, dynamic> item) async {
    final data = item['data'] is Map<String, dynamic>
        ? item['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final dataType = ((data['notificationType'] ?? item['type'] ?? '')
            .toString())
        .toLowerCase();
    final houseId = item['house_id'] ?? data['houseId'];

    if (dataType == 'verification' ||
        dataType.startsWith('verification_') ||
        dataType == 'payment' ||
        dataType == 'maintenance' ||
        dataType == 'alert') {
      await AppNavigationService.openFromNotification({
        ...data,
        ...item,
        if (houseId != null) 'houseId': houseId,
      });
      return;
    }

    if (houseId != null) {
      await _openNotificationHouse(data: data, houseId: houseId);
      return;
    }

    await AppNavigationService.openFromNotification({
      ...data,
      ...item,
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

  Future<void> _markNotificationRead(Object? notificationId) async {
    if (notificationId == null) return;
    final success = await ApiService.markNotificationAsRead(
      notificationId.toString(),
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Imeshindikana kuhifadhi notification.',
              en: 'Could not mark notification as read.',
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
    if (combined.contains('uthibitishaji') ||
        combined.contains('verification') ||
        combined.contains('verify')) {
      return Icons.verified_user_rounded;
    }
    if (combined.contains('payment') ||
        combined.contains('rent') ||
        combined.contains('kodi') ||
        combined.contains('malipo')) {
      return Icons.payments_rounded;
    }
    if (combined.contains('ombi') ||
        combined.contains('maombi') ||
        combined.contains('apply') ||
        combined.contains('approved') ||
        combined.contains('imekubaliwa')) {
      return Icons.assignment_turned_in_rounded;
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
    if (combined.contains('uthibitishaji') ||
        combined.contains('verification') ||
        combined.contains('verify')) {
      return const Color(0xFF8B5CF6);
    }
    if (combined.contains('payment') ||
        combined.contains('rent') ||
        combined.contains('kodi') ||
        combined.contains('malipo')) {
      return const Color(0xFF2457D6);
    }
    if (combined.contains('imekubaliwa') || combined.contains('approved')) {
      return const Color(0xFF4CAF50);
    }
    if (combined.contains('ukarabati')) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFF0F8B61);
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Map<String, dynamic> data,
    required Object? houseId,
    required Object? notificationId,
    required String dataType,
    required bool isAppNotif,
    required bool canOpen,
    required Color notifColor,
  }) {
    final buttons = <Widget>[
      OutlinedButton.icon(
        onPressed: () => _markNotificationRead(notificationId),
        icon: const Icon(Icons.done_rounded, size: 18),
        label: Text(
          context.tr(
            'Mark read',
            en: 'Mark read',
          ),
        ),
      ),
    ];

    if (isAppNotif) {
      final primaryLabel = dataType == 'verification' ||
              dataType.startsWith('verification_')
          ? context.tr('Verify now', en: 'Verify now')
          : context.tr('Open', en: 'Open');
      buttons.insert(
        0,
        FilledButton.icon(
          onPressed: () => _openNotificationItem(item),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(primaryLabel),
          style: FilledButton.styleFrom(
            backgroundColor: notifColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (canOpen) {
      buttons.insert(
        0,
        FilledButton.icon(
          onPressed: () => _openNotificationHouse(
            data: data,
            houseId: houseId,
          ),
          icon: const Icon(Icons.home_rounded, size: 18),
          label: Text(
            context.tr(
              'Open house',
              en: 'Open house',
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: notifColor,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: buttons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF46D39A)
        : const Color(0xFF0F8B61);
    final bgColor = isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8);
    final cardBg = isDark ? const Color(0xFF171C1A) : Colors.white;
    final textColor = isDark ? const Color(0xFFF2F7F4) : const Color(0xFF15201C);
    final subtextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          context.tr(
            'Arifa & Taarifa',
            en: 'Notifications',
          ),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: context.tr(
              'Miingiliano ya Akili',
              en: 'Smart alerts',
            ),
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
                  _buildFilterChip(
                    context.tr('Zote', en: 'All'),
                    'all',
                    isDark,
                    primaryColor,
                  ),
                  _buildFilterChip(
                    context.tr('Nyumba Mpya', en: 'New Houses'),
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
                              context.tr(
                                'Imeshindwa kupakia arifa.',
                                en: 'Failed to load notifications.',
                              ),
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
                        'title': context.tr(
                          'Maombi Yako Yamekubaliwa! 🎉',
                          en: 'Your Application Accepted! 🎉',
                        ),
                        'body': context.tr(
                          'Mwenye nyumba wa "Apartment ya Kisasa - Makumbusho" amekubali maombi yako. Unaweza kulipa deposit sasa ili kuhifadhi nyumba.',
                          en: 'The landlord of "Modern Apartment - Makumbusho" has accepted your application. You can pay the deposit now to secure the house.',
                        ),
                        'created_at': DateTime.now()
                            .subtract(const Duration(minutes: 45))
                            .toIso8601String(),
                        'type': 'application',
                      },
                      {
                        'id': 'notif-2',
                        'title': context.tr(
                          'Kumbukumbu ya Malipo ya Kodi 💡',
                          en: 'Rent Payment Reminder 💡',
                        ),
                        'body': context.tr(
                          'Kodi ya mwezi ujao kwa nyumba ya Sinza Mori inatarajiwa kulipwa ndani ya siku 14.',
                          en: 'Next month rent for the Sinza Mori house is expected to be paid within 14 days.',
                        ),
                        'created_at': DateTime.now()
                            .subtract(const Duration(days: 1))
                            .toIso8601String(),
                        'type': 'payment',
                      },
                      {
                        'id': 'notif-3',
                        'title': context.tr(
                          'Nyumba Mpya Karibu na UDOM! 🎓',
                          en: 'New House Near UDOM! 🎓',
                        ),
                        'body': context.tr(
                          'Vyumba 4 vipya vya wanafunzi vyenye tiles na maji ndani vimeongezwa Chuo Kikuu Dodoma.',
                          en: '4 new student rooms with tiles and running water have been added at the University of Dodoma.',
                        ),
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
                      if (_selectedFilter == 'houses') {
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
                      final dataType = ((item['data'] is Map<String, dynamic>
                              ? item['data']['notificationType']
                              : null) ??
                          item['type'] ??
                          '')
                          .toString()
                          .toLowerCase();
                      final notifIcon = _getNotificationIcon(title, body);
                      final notifColor = _getNotificationColor(title, body);
                      final notificationId = item['id']?.toString();

                      final isAppNotif = dataType == 'verification' ||
                          dataType.startsWith('verification_') ||
                          dataType == 'payment' ||
                          dataType == 'maintenance' ||
                          dataType == 'alert' ||
                          title.toLowerCase().contains('ombi') ||
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
                                  ? const Color(0xFF26312D)
                                  : const Color(0xFFE2E8E5),
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
                              _openNotificationItem(item);
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
                                        const SizedBox(height: 12),
                                        _buildActionButtons(
                                          context: context,
                                          item: item,
                                          data: data,
                                          houseId: houseId,
                                          notificationId: notificationId,
                                          dataType: dataType,
                                          isAppNotif: isAppNotif,
                                          canOpen: canOpen,
                                          notifColor: notifColor,
                                        ),
                                        if (isAppNotif) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            context.tr(
                                              'Bofya kufungua arifa hii →',
                                              en: 'Tap to open this notification →',
                                            ),
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
              : (isDark ? const Color(0xFF26312D) : const Color(0xFFE2E8E5)),
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
