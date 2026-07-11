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
    RealtimeService.instance.on('house:created', _handleRealtimeNotification);
  }

  @override
  void dispose() {
    RealtimeService.instance.off('house:created', _handleRealtimeNotification);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Arifa', en: 'Notifications')),
        actions: [
          IconButton(
            tooltip: l10n.tr('Smart alerts', en: 'Smart alerts'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SmartAlertSettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.tune_rounded),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = notifications[index] as Map<String, dynamic>;
                final data = item['data'] is Map<String, dynamic>
                    ? item['data'] as Map<String, dynamic>
                    : <String, dynamic>{};
                final houseId = item['house_id'] ?? data['houseId'];

                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: ListTile(
                    onTap: houseId == null
                        ? null
                        : () {
                            AppNavigationService.openHouseFromNotification({
                              ...data,
                              'houseId': houseId,
                            });
                          },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: colors.primary,
                      ),
                    ),
                    title: Text(
                      item['title']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item['body']?.toString() ?? ''),
                    ),
                    trailing: Text(
                      _formatDate(item['created_at']),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
