import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/pages/smart_alert_settings_page.dart';
import 'package:serkapp/services/app_navigation_service.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/services/realtime_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<dynamic>> _notificationsFuture;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Arifa', en: 'Notifications')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'alerts':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SmartAlertSettingsPage(),
                    ),
                  );
                  break;
                case 'refresh':
                  _refresh();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'alerts',
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(l10n.tr('Smart alerts', en: 'Smart alerts')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(l10n.tr('Refresh', en: 'Refresh')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 54,
                    color: colors.error,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.tr(
                      'Imeshindwa kupakia arifa.',
                      en: 'Could not load notifications.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              );
            }

            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 130),
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 62,
                    color: colors.primary.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tr('Hakuna arifa bado', en: 'No notifications yet'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.tr(
                      'Nyumba mpya zikiongezwa zitaonekana hapa.',
                      en: 'Newly added houses will appear here.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = notifications[index] as Map<String, dynamic>;
                final data = item['data'] is Map<String, dynamic>
                    ? item['data'] as Map<String, dynamic>
                    : <String, dynamic>{};
                final houseId = item['house_id'] ?? data['houseId'];
                final canOpen = houseId != null;

                return Dismissible(
                  key: ValueKey(item['id']?.toString() ?? index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteNotification(item['id']),
                  child: Material(
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: canOpen
                          ? () => _openNotificationHouse(
                                data: data,
                                houseId: houseId,
                              )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.11),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.home_work_rounded,
                                size: 19,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title']?.toString() ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(item['created_at']),
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['body']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                                  ),
                                  if (canOpen) ...[
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => _openNotificationHouse(
                                          data: data,
                                          houseId: houseId,
                                        ),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(0, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 15,
                                        ),
                                        label: Text(
                                          l10n.tr('Ona zaidi', en: 'View more'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
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
    );
  }
}
