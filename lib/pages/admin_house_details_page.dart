import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/widgets/loading_states.dart';
import 'package:serik/widgets/pull_to_refresh.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHouseDetailsPage extends StatefulWidget {
  final String houseId;

  const AdminHouseDetailsPage({super.key, required this.houseId});

  @override
  State<AdminHouseDetailsPage> createState() => _AdminHouseDetailsPageState();
}

class _AdminHouseDetailsPageState extends State<AdminHouseDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _houseData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHouseDetails();
  }

  Future<void> _loadHouseDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHouseDetailsAdmin(widget.houseId);
      if (!mounted) return;
      setState(() {
        _houseData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.tr('Imeshindikana kupakia maelezo ya nyumba', en: 'Failed to load house details');
        _isLoading = false;
      });
    }
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
        title: Text(l10n.tr('Maelezo ya Nyumba', en: 'House Details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: _houseData != null && _houseData!['latitude'] != 0
                ? () => _showOnMap()
                : null,
            tooltip: l10n.tr('Ona kwenye Ramani', en: 'View on Map'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _houseData != null ? () => _showLandlordProfile() : null,
            tooltip: l10n.tr('Profaili ya Mwenye Nyumba', en: 'Landlord Profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(
              message: 'Loading house details...',
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
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHouseDetails,
                        child: Text(l10n.tr('Jaribu Tena', en: 'Retry')),
                      ),
                    ],
                  ),
                )
              : _houseData == null
                  ? const Center(child: Text('No house data'))
                  : RefreshIndicator(
                      onRefresh: _loadHouseDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHouseHeader(isDark, cardColor, textColor, subtextColor, primaryColor, l10n),
                            const SizedBox(height: 24),
                            _buildStatusCard(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildLocationCard(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildDetailsCard(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildAmenitiesCard(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildMediaSection(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildLandlordCard(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildVerificationCard(isDark, cardColor, textColor, subtextColor, borderColor, l10n),
                            const SizedBox(height: 24),
                            _buildActionsCard(isDark, cardColor, textColor, subtextColor, borderColor, primaryColor, l10n),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHouseHeader(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color primaryColor, AppLocalizations l10n) {
    final house = _houseData!;
    final images = house['images'] as List<dynamic>? ?? [];
    final primaryImage = images.isNotEmpty ? images[0].toString() : null;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (primaryImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: primaryImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  house['brandName']?.toString() ?? house['ownerName']?.toString() ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriceChip(house['rentPrice'], isDark, primaryColor),
                    const SizedBox(width: 12),
                    _buildTypeChip(house['type']?.toString() ?? 'House', isDark),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  house['locationAddress']?.toString() ?? 'Unknown location',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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

  Widget _buildPriceChip(dynamic price, bool isDark, Color primaryColor) {
    final priceValue = price is num ? price : double.tryParse(price.toString()) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'TZS ${_formatPrice(priceValue)}/mo',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;
    final status = house['status']?.toString() ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    final rejectionReason = house['rejectionReason']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Hali ya Nyumba', en: 'House Status'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
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
                      rejectionReason,
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
    );
  }

  Widget _buildLocationCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;
    final lat = house['latitude'] is num 
        ? (house['latitude'] as num).toDouble() 
        : double.tryParse(house['latitude'].toString()) ?? 0;
    final lng = house['longitude'] is num 
        ? (house['longitude'] as num).toDouble() 
        : double.tryParse(house['longitude'].toString()) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Mahali', en: 'Location'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLocationRow(l10n.tr('Mkoa', en: 'Region'), house['region']?.toString() ?? '-', textColor, subtextColor),
            _buildLocationRow(l10n.tr('Wilaya', en: 'District'), house['district']?.toString() ?? '-', textColor, subtextColor),
            _buildLocationRow(l10n.tr('Kata', en: 'Ward'), house['ward']?.toString() ?? '-', textColor, subtextColor),
            _buildLocationRow(l10n.tr('Kijiji/Mtaa', en: 'Village/Street'), house['street']?.toString() ?? '-', textColor, subtextColor),
            if (lat != 0 && lng != 0) ...[
              const SizedBox(height: 12),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(house['id'].toString()),
                      position: LatLng(lat, lng),
                    ),
                  },
                  liteModeEnabled: true,
                  myLocationEnabled: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bed_outlined, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Maelezo', en: 'Details'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(l10n.tr('Vyumba vya kulala', en: 'Bedrooms'), house['bedrooms']?.toString() ?? '-', textColor, subtextColor),
            _buildDetailRow(l10n.tr('Amani ya Kukodi', en: 'Deposit'), _formatPrice(house['depositAmount']), textColor, subtextColor),
            if (house['description']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                house['description'].toString(),
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;
    final amenities = <String>[];

    if (house['waterIncluded'] == true) amenities.add(l10n.tr('Maji', en: 'Water'));
    if (house['electricityIncluded'] == true) amenities.add(l10n.tr('Umeme', en: 'Electricity'));
    if (house['internetIncluded'] == true) amenities.add(l10n.tr('Intaneti', en: 'Internet'));

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedroom_parent_outlined, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Vitu Vinavyopatikana', en: 'Amenities'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (amenities.isEmpty)
              Text(
                l10n.tr('Hakuna vitu vinavyopatikana vilivyorekodiwa', en: 'No amenities listed'),
                style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map((amenity) => Chip(
                  label: Text(amenity, style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;
    final images = house['images'] as List<dynamic>? ?? [];
    final videos = house['videos'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Picha na Video', en: 'Photos & Videos'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (images.isEmpty)
              Text(
                l10n.tr('Hakuna picha', en: 'No photos'),
                style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: images[index].toString(),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(Icons.broken_image, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (videos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${l10n.tr('Video', en: 'Videos')}: ${videos.length}',
                style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLandlordCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;
    final landlord = house['landlord'];

    if (landlord == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Mwenye Nyumba', en: 'Landlord'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLandlordRow(l10n.tr('Jina', en: 'Name'), '${landlord['firstName']} ${landlord['lastName']}'.trim(), textColor, subtextColor),
            _buildLandlordRow(l10n.tr('Barua pepe', en: 'Email'), landlord['email']?.toString() ?? '-', textColor, subtextColor),
            _buildLandlordRow(l10n.tr('Namba ya simu', en: 'Phone'), landlord['phone']?.toString() ?? '-', textColor, subtextColor),
            const SizedBox(height: 8),
            Row(
              children: [
                if (landlord['isBanned'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      l10n.tr('Akaunti Imefungwa', en: 'Account Banned'),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandlordRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, AppLocalizations l10n) {
    final house = _houseData!;
    final landlord = house['landlord'];

    if (landlord == null) {
      return const SizedBox.shrink();
    }

    final identityStatus = landlord['identityVerificationStatus']?.toString() ?? 'not_submitted';
    final propertyStatus = landlord['propertyVerificationStatus']?.toString() ?? 'not_submitted';
    final houseStatus = house['status']?.toString() ?? 'unknown';
    final createdAt = house['createdAt']?.toString();
    final updatedAt = house['updatedAt']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Hali ya Uthibitishaji', en: 'Verification Status'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVerificationRow(l10n.tr('Uthibitishaji wa Identity', en: 'Identity Verification'), identityStatus, textColor, subtextColor),
            _buildVerificationRow(l10n.tr('Uthibitishaji wa Mali', en: 'Property Verification'), propertyStatus, textColor, subtextColor),
            const SizedBox(height: 12),
            Divider(color: borderColor),
            const SizedBox(height: 12),
            Text(
              l10n.tr('Historia ya Nyumba', en: 'House History'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildHistoryRow(l10n.tr('Hali ya Sasa', en: 'Current Status'), houseStatus, textColor, subtextColor),
            if (createdAt != null) _buildHistoryRow(l10n.tr('Ilipwa', en: 'Created'), createdAt, textColor, subtextColor),
            if (updatedAt != null) _buildHistoryRow(l10n.tr('Imebadilishwa', en: 'Last Updated'), updatedAt, textColor, subtextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRow(String label, String status, Color textColor, Color subtextColor) {
    final statusColor = _getVerificationStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: subtextColor),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12, color: textColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool isDark, Color cardColor, Color textColor, Color subtextColor, Color borderColor, Color primaryColor, AppLocalizations l10n) {
    final house = _houseData!;
    final status = house['status']?.toString() ?? 'Unknown';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('Vitendo vya Admin', en: 'Admin Actions'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status != 'Inapatikana')
                  ElevatedButton.icon(
                    onPressed: _approveHouse,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.tr('Idhinisha', en: 'Approve')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status != 'Imekataliwa')
                  ElevatedButton.icon(
                    onPressed: _rejectHouse,
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(l10n.tr('Kataa', en: 'Reject')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status != 'Imefichwa')
                  OutlinedButton.icon(
                    onPressed: _hideHouse,
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: Text(l10n.tr('Ficha', en: 'Hide')),
                  ),
                if (status == 'Imefichwa')
                  OutlinedButton.icon(
                    onPressed: _unhideHouse,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.tr('Fichua', en: 'Unhide')),
                  ),
                OutlinedButton.icon(
                  onPressed: _deleteHouse,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.tr('Futa', en: 'Delete')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'inapatikana':
      case 'active':
        return Colors.green;
      case 'imekataliwa':
      case 'rejected':
        return Colors.red;
      case 'imefichwa':
      case 'hidden':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getVerificationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
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

  void _showOnMap() {
    final house = _houseData!;
    final lat = house['latitude'] is num ? house['latitude'] : double.tryParse(house['latitude'].toString()) ?? 0;
    final lng = house['longitude'] is num ? house['longitude'] : double.tryParse(house['longitude'].toString()) ?? 0;

    // Navigate to map with this property
    // For now, show a dialog since we don't have the map page navigation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Mahali pa Nyumba', en: 'House Location')),
        content: Text('Lat: $lat, Lng: $lng'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Funga', en: 'Close')),
          ),
        ],
      ),
    );
  }

  void _showLandlordProfile() {
    final house = _houseData!;
    final landlord = house['landlord'];

    if (landlord == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Profaili ya Mwenye Nyumba', en: 'Landlord Profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLandlordDetail(context.tr('Jina', en: 'Name'), '${landlord['firstName']} ${landlord['lastName']}'.trim()),
              _buildLandlordDetail(context.tr('Barua pepe', en: 'Email'), landlord['email']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Namba ya simu', en: 'Phone'), landlord['phone']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Role', en: 'Role'), landlord['role']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Hali ya akaunti', en: 'Account Status'), landlord['isBanned'] == true ? context.tr('Imefungwa', en: 'Banned') : context.tr('Inatumika', en: 'Active')),
              const SizedBox(height: 16),
              Text(
                context.tr('Uthibitishaji wa Identity', en: 'Identity Verification'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildLandlordDetail(context.tr('Hali', en: 'Status'), landlord['identityVerificationStatus']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Ilipwa', en: 'Submitted'), landlord['identitySubmittedAt']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Imetathminiwa', en: 'Reviewed'), landlord['identityReviewedAt']?.toString() ?? '-'),
              const SizedBox(height: 16),
              Text(
                context.tr('Uthibitishaji wa Mali', en: 'Property Verification'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildLandlordDetail(context.tr('Hali', en: 'Status'), landlord['propertyVerificationStatus']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Ilipwa', en: 'Submitted'), landlord['propertySubmittedAt']?.toString() ?? '-'),
              _buildLandlordDetail(context.tr('Imetathminiwa', en: 'Reviewed'), landlord['propertyReviewedAt']?.toString() ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Funga', en: 'Close')),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _approveHouse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Idhinisha Nyumba', en: 'Approve House')),
        content: Text(context.tr('Una hakika unataka idhinisha nyumba hii?', en: 'Are you sure you want to approve this house?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Idhinisha', en: 'Approve')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.approveHouse(widget.houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imeidhinishwa!', en: 'House approved!'))),
        );
        await _loadHouseDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kuidhinisha nyumba', en: 'Failed to approve house'))),
        );
      }
    }
  }

  Future<void> _rejectHouse() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Kataa Nyumba', en: 'Reject House')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('Sababu ya kukataa ni lazima:', en: 'Rejection reason is required:')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: context.tr('Sababu', en: 'Reason'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reason is required')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(context.tr('Kataa', en: 'Reject')),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      final success = await ApiService.rejectHouse(widget.houseId, reasonController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imekataliwa!', en: 'House rejected!'))),
        );
        await _loadHouseDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kukataa nyumba', en: 'Failed to reject house'))),
        );
      }
    }
  }

  Future<void> _hideHouse() async {
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
      final success = await ApiService.hideHouse(widget.houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imefichwa!', en: 'House hidden!'))),
        );
        await _loadHouseDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kuficha nyumba', en: 'Failed to hide house'))),
        );
      }
    }
  }

  Future<void> _unhideHouse() async {
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
      final success = await ApiService.unhideHouse(widget.houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imefichuliwa!', en: 'House unhidden!'))),
        );
        await _loadHouseDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kufichua nyumba', en: 'Failed to unhide house'))),
        );
      }
    }
  }

  Future<void> _deleteHouse() async {
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
      final success = await ApiService.deleteHouseAdmin(widget.houseId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Nyumba imefutwa!', en: 'House deleted!'))),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Imeshindikana kufuta nyumba', en: 'Failed to delete house'))),
        );
      }
    }
  }
}
