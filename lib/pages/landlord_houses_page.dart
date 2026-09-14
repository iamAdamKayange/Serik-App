import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/widgets/loading_states.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/pages/house_registration_page.dart';

class LandlordHousesPage extends StatefulWidget {
  const LandlordHousesPage({super.key});

  @override
  State<LandlordHousesPage> createState() => _LandlordHousesPageState();
}

class _LandlordHousesPageState extends State<LandlordHousesPage> {
  bool _isLoading = true;
  List<dynamic> _houses = [];
  String? _errorMessage;
  String _filterStatus = 'all'; // all, pending, approved, rejected, hidden

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    setState(() => _isLoading = true);
    try {
      final houses = await ApiService.getMyHouses();
      if (!mounted) return;
      setState(() {
        _houses = houses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.tr('Imeshindikana kupakia nyumba zako', en: 'Failed to load your houses');
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredHouses {
    if (_filterStatus == 'all') return _houses;
    return _houses.where((house) {
      final status = house['status']?.toString().toLowerCase() ?? '';
      switch (_filterStatus) {
        case 'pending':
          return status == 'pending_verification';
        case 'approved':
          return status == 'inapatikana';
        case 'rejected':
          return status == 'imekataliwa';
        case 'hidden':
          return status == 'imefichwa';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    final backgroundColor = isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0D1117);
    final subtextColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76);
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(l10n.tr('Nyumba Zangu', en: 'My Houses')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HouseRegistrationForm(),
                ),
              ).then((_) => _loadHouses());
            },
            tooltip: l10n.tr('Ongeza Nyumba', en: 'Add House'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(
              message: 'Loading your houses...',
              variant: LoadingVariant.circular,
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: subtextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHouses,
                        child: Text(l10n.tr('Jaribu Tena', en: 'Retry')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(l10n.tr('Zote', en: 'All'), 'all', isDark, primaryColor),
                            const SizedBox(width: 8),
                            _buildFilterChip(l10n.tr('Inasubiri', en: 'Pending'), 'pending', isDark, primaryColor),
                            const SizedBox(width: 8),
                            _buildFilterChip(l10n.tr('Imeidhinishwa', en: 'Approved'), 'approved', isDark, primaryColor),
                            const SizedBox(width: 8),
                            _buildFilterChip(l10n.tr('Imekataliwa', en: 'Rejected'), 'rejected', isDark, primaryColor),
                            const SizedBox(width: 8),
                            _buildFilterChip(l10n.tr('Imefichwa', en: 'Hidden'), 'hidden', isDark, primaryColor),
                          ],
                        ),
                      ),
                    ),
                    // Houses list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadHouses,
                        child: _filteredHouses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.home_outlined, size: 64, color: subtextColor),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.tr('Hakuna nyumba zilizopatikana', en: 'No houses found'),
                                      style: GoogleFonts.poppins(color: subtextColor),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredHouses.length,
                                itemBuilder: (context, index) {
                                  return _buildHouseCard(_filteredHouses[index], isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark, Color primaryColor) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      selectedColor: primaryColor.withValues(alpha: 0.2),
      checkmarkColor: primaryColor,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
        fontSize: 12,
      ),
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  Widget _buildHouseCard(dynamic house, bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, Color primaryColor, AppLocalizations l10n) {
    final status = house['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final images = house['images'] as List<dynamic>? ?? [];
    final primaryImage = images.isNotEmpty ? images[0].toString() : null;
    final houseId = house['id']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: houseId != null ? () => _showHouseDetails(house) : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (primaryImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: primaryImage,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          house['brand_name']?.toString() ?? house['owner_name']?.toString() ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _getStatusLabel(status, l10n),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Text(
                    house['location_address']?.toString() ?? 'Unknown location',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Row(
                    children: [
                      Text(
                        'TZS ${_formatPrice(house['rent_price'])}/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Action buttons
                      if (status.toLowerCase() == 'imekataliwa')
                        _buildActionButton(
                          Icons.edit,
                          l10n.tr('Rekebisha', en: 'Fix'),
                          isDark,
                          primaryColor,
                          () => _editHouse(house),
                        ),
                      if (status.toLowerCase() == 'inapatikana')
                        _buildActionButton(
                          Icons.visibility_off,
                          l10n.tr('Ficha', en: 'Hide'),
                          isDark,
                          Colors.orange,
                          () => _hideHouse(houseId),
                        ),
                      if (status.toLowerCase() == 'imefichwa')
                        _buildActionButton(
                          Icons.visibility,
                          l10n.tr('Fichua', en: 'Unhide'),
                          isDark,
                          Colors.green,
                          () => _unhideHouse(houseId),
                        ),
                      _buildActionButton(
                        Icons.delete_outline,
                        l10n.tr('Futa', en: 'Delete'),
                        isDark,
                        Colors.red,
                        () => _deleteHouse(houseId),
                      ),
                    ],
                  ),
                  // Rejection reason
                  if (status.toLowerCase() == 'imekataliwa' && house['rejection_reason']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                l10n.tr('Sababu ya kukataliwa:', en: 'Rejection reason:'),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            house['rejection_reason'].toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool isDark, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'inapatikana':
      case 'approved':
        return Colors.green;
      case 'imekataliwa':
      case 'rejected':
        return Colors.red;
      case 'imefichwa':
      case 'hidden':
        return Colors.orange;
      case 'pending_verification':
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'inapatikana':
        return l10n.tr('Inapatikana', en: 'Available');
      case 'imekataliwa':
        return l10n.tr('Imekataliwa', en: 'Rejected');
      case 'imefichwa':
        return l10n.tr('Imefichwa', en: 'Hidden');
      case 'pending_verification':
        return l10n.tr('Inasubiri', en: 'Pending');
      default:
        return status;
    }
  }

  String _formatPrice(dynamic value) {
    if (value is num) {
      final numValue = value;
      if (numValue >= 1000000) {
        return '${(numValue / 1000000).toStringAsFixed(1)}M';
      } else if (numValue >= 1000) {
        return '${(numValue / 1000).toStringAsFixed(0)}K';
      }
      return numValue.toStringAsFixed(0);
    }
    return value.toString();
  }

  void _showHouseDetails(dynamic house) {
    showDialog(
      context: context,
      builder: (context) => _HouseDetailsDialog(house: house),
    );
  }

  void _editHouse(dynamic house) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HouseRegistrationForm(existingHouse: house),
      ),
    ).then((_) => _loadHouses());
  }

  Future<void> _hideHouse(String? houseId) async {
    if (houseId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Ficha Nyumba', en: 'Hide House')),
        content: Text(context.tr('Una hakika unataka ficha nyumba hii?', en: 'Are you sure you want to hide this house?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Ficha', en: 'Hide')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.hideHouse(houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imefichwa!', en: 'House hidden!'))),
        );
        await _loadHouses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kuficha nyumba', en: 'Failed to hide house'))),
        );
      }
    }
  }

  Future<void> _unhideHouse(String? houseId) async {
    if (houseId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Fichua Nyumba', en: 'Unhide House')),
        content: Text(context.tr('Una hakika unataka fichua nyumba hii?', en: 'Are you sure you want to unhide this house?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Fichua', en: 'Unhide')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.unhideHouse(houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imefichuliwa!', en: 'House unhidden!'))),
        );
        await _loadHouses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kufichua nyumba', en: 'Failed to unhide house'))),
        );
      }
    }
  }

  Future<void> _deleteHouse(String? houseId) async {
    if (houseId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Futa Nyumba', en: 'Delete House')),
        content: Text(context.tr('Hatendea hili - hii itafutwa kabisa!', en: 'Warning - this will delete the house permanently!')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('Futa', en: 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.deleteHouse(houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imefutwa!', en: 'House deleted!'))),
        );
        await _loadHouses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kufuta nyumba', en: 'Failed to delete house'))),
        );
      }
    }
  }
}

class _HouseDetailsDialog extends StatelessWidget {
  final dynamic house;

  const _HouseDetailsDialog({required this.house});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0D1117);
    final subtextColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(l10n.tr('Maelezo ya Nyumba', en: 'House Details')),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(l10n.tr('Jina', en: 'Name'), house['brand_name']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Aina', en: 'Type'), house['type']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Vyumba vya kulala', en: 'Bedrooms'), house['bedrooms']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Bei', en: 'Price'), 'TZS ${_formatPrice(house['rent_price'])}/mo', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Amani ya Kukodi', en: 'Deposit'), 'TZS ${_formatPrice(house['deposit_amount'])}', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Anwani', en: 'Address'), house['location_address']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Mkoa', en: 'Region'), house['region']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Wilaya', en: 'District'), house['district']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Kata', en: 'Ward'), house['ward']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Hali', en: 'Status'), house['status']?.toString() ?? '-', textColor, subtextColor),
                    if (house['rejection_reason']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr('Sababu ya kukataliwa:', en: 'Rejection reason:'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              house['rejection_reason'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('Maelezo', en: 'Description'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      house['description']?.toString() ?? l10n.tr('Hakuna maelezo', en: 'No description'),
                      style: GoogleFonts.poppins(fontSize: 13, color: subtextColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('Vitu Vinavyopatikana', en: 'Amenities'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (house['water_included'] == true)
                          Chip(label: Text(l10n.tr('Maji', en: 'Water'))),
                        if (house['electricity_included'] == true)
                          Chip(label: Text(l10n.tr('Umeme', en: 'Electricity'))),
                        if (house['internet_included'] == true)
                          Chip(label: Text(l10n.tr('Intaneti', en: 'Internet'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('Taarifa', en: 'Info'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(l10n.tr('Ilipwa', en: 'Created'), house['created_at']?.toString() ?? '-', textColor, subtextColor),
                    _buildDetailRow(l10n.tr('Imebadilishwa', en: 'Updated'), house['updated_at']?.toString() ?? '-', textColor, subtextColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: subtextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic value) {
    if (value is num) {
      final numValue = value;
      if (numValue >= 1000000) {
        return '${(numValue / 1000000).toStringAsFixed(1)}M';
      } else if (numValue >= 1000) {
        return '${(numValue / 1000).toStringAsFixed(0)}K';
      }
      return numValue.toStringAsFixed(0);
    }
    return value.toString();
  }
}
