// lib/pages/houses_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/pages/house_registration_page.dart';

class HousesPage extends StatefulWidget {
  final List<HouseData> houses;
  final VoidCallback onRefresh;

  const HousesPage({super.key, required this.houses, required this.onRefresh});

  @override
  State<HousesPage> createState() => _HousesPageState();
}

class _HousesPageState extends State<HousesPage> {
  bool _isProcessing = false;

  Future<void> _editHouse(HouseData house) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseRegistrationForm(
          existingHouse: house,
          onHouseAdded: (updatedHouse) {
            widget.onRefresh(); // Refresh after edit
          },
        ),
      ),
    );
    if (result == true) widget.onRefresh();
  }

  Future<void> _deleteHouse(HouseData house) async {
    // Step 1: Dialog ya kuthibitisha
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Futa Nyumba', en: 'Delete House')),
        content: Text(
          context.tr(
            'Je, una uhakika unataka kufuta "${house.name}"? Hatua hii haiwezi kubatilishwa.',
            en: 'Are you sure you want to delete "${house.name}"? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              context.tr(
                'Futa, nina uhakika',
                en: 'Delete, I am sure',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // Step 2: Onyesha loading dialog wakati wa kufuta
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Inafuta nyumba "${house.name}"...',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Tafadhali subiri', en: 'Please wait'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    setState(() => _isProcessing = true);

    try {
      final success = await ApiService.deleteHouse(house.id);

      // Funga loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        // Step 3: Onyesha dialog ya mafanikio
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(context.tr('Imefanikiwa', en: 'Success')),
              ],
            ),
            content: Text(
              context.tr(
                'Nyumba imefutwa kikamilifu!',
                en: 'House deleted successfully!',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('Sawa', en: 'OK')),
              ),
            ],
          ),
        );
        // Refresh list
        widget.onRefresh();
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      // Funga loading dialog ikiwa bado ipo
      if (!mounted) return;
      Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(context.tr('Hitilafu', en: 'Error')),
            ],
          ),
          content: Text(
            context.tr(
              'Imeshindwa kufuta nyumba. Tafadhali jaribu tena.',
              en: 'Could not delete the house. Please try again.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('Jaribu tena', en: 'Try again')),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    if (widget.houses.isEmpty) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          title: Text(context.tr('Nyumba Zangu', en: 'My Houses')),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 80,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(
                  'Hakuna nyumba zilizosajiliwa',
                  en: 'No registered houses',
                ),
                style: TextStyle(fontSize: 16, color: subtextColor),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Bonyeza kitufe cha "+" kuongeza nyumba',
                  en: 'Tap the "+" button to add a house',
                ),
                style: TextStyle(fontSize: 14, color: subtextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(context.tr('Nyumba Zangu', en: 'My Houses')),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.onRefresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.houses.length,
          itemBuilder: (context, index) {
            final house = widget.houses[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                house.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                house.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _editHouse(house),
                          tooltip: context.tr('Hariri', en: 'Edit'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _deleteHouse(house),
                          tooltip: context.tr('Futa', en: 'Delete'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.attach_money,
                            '${context.tr('Kodi', en: 'Rent')}: TZS ${NumberFormat('#,###').format(house.rentPrice)}',
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            Icons.bed,
                            '${context.tr('Vyumba', en: 'Rooms')}: ${house.bedrooms}',
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatusChip(house.status, isDarkMode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isDarkMode) {
    Color bgColor;
    Color textColor;
    if (status.toLowerCase().contains('kodishwa') ||
        status.toLowerCase() == 'imekodishwa') {
      bgColor = Colors.green.withValues(alpha: 0.2);
      textColor = Colors.green;
    } else if (status.toLowerCase().contains('malizika')) {
      bgColor = Colors.orange.withValues(alpha: 0.2);
      textColor = Colors.orange;
    } else {
      bgColor = Colors.grey.withValues(alpha: 0.2);
      textColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}
