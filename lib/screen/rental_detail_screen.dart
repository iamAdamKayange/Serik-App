import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../model/rental_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/saved_house_button.dart';

class RentalDetailScreen extends StatelessWidget {
  final RentalSpot spot;

  const RentalDetailScreen({super.key, required this.spot});

  void _showFullScreenImage(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${initialIndex + 1} / ${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 NEW: Play video inside a dialog with video_player
  void _playVideo(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final cardHeaderBg = isDark
        ? primaryColor.withValues(alpha: 0.15)
        : primaryColor.withValues(alpha: 0.05);

    // Prepare owner name and phone using new fields
    String ownerName = spot.ownerName.trim();
    if (ownerName.isEmpty) ownerName = "Mwenye Nyumba";
    String ownerPhone = spot.phone.trim();
    if (ownerPhone.isEmpty) ownerPhone = "Hajabainishwa";
    String brandName = spot.brandName.trim();
    if (brandName.isEmpty) brandName = "Nyumba";
    String houseNumber = spot.houseNumber.trim();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Maelezo ya Nyumba',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          SavedHouseButton(houseId: spot.id),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            GestureDetector(
              onTap: spot.hasImages()
                  ? () => _showFullScreenImage(context, spot.images, 0)
                  : null,
              child: Container(
                height: 280,
                width: double.infinity,
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                child: spot.hasImages()
                    ? CachedNetworkImage(
                        imageUrl: spot.images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, _) => Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                        errorWidget: (_, _, _) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: isDark ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.home_rounded,
                          size: 80,
                          color: isDark ? Colors.grey[600] : Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand name (jina maarufu)
                  Text(
                    brandName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Type badge + house number
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          spot.type,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (houseNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.numbers,
                                size: 14,
                                color: subtextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Namba $houseNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Owner Info Card
                  _buildOwnerCard(
                    ownerName,
                    ownerPhone,
                    isDark,
                    primaryColor,
                    subtextColor,
                    borderColor,
                    cardHeaderBg,
                  ),

                  const SizedBox(height: 16),

                  // Address Card
                  _buildAddressCard(
                    spot,
                    isDark,
                    primaryColor,
                    subtextColor,
                    borderColor,
                    cardHeaderBg,
                  ),

                  const SizedBox(height: 16),

                  // Price Card
                  _buildPriceCard(
                    spot,
                    isDark,
                    primaryColor,
                    textColor,
                    subtextColor,
                    borderColor,
                    cardHeaderBg,
                  ),

                  const SizedBox(height: 16),

                  // Features Card
                  _buildFeaturesCard(
                    spot,
                    isDark,
                    primaryColor,
                    subtextColor,
                    borderColor,
                    cardHeaderBg,
                  ),

                  const SizedBox(height: 16),

                  // Description Card
                  _buildDescriptionCard(
                    spot,
                    isDark,
                    textColor,
                    subtextColor,
                    borderColor,
                    cardHeaderBg,
                    primaryColor,
                  ),

                  const SizedBox(height: 16),

                  // Nearby Amenities
                  if (spot.getNearbyAmenitiesList().isNotEmpty)
                    _buildAmenitiesCard(
                      spot,
                      isDark,
                      primaryColor,
                      subtextColor,
                      borderColor,
                      cardHeaderBg,
                    ),

                  // Video Section
                  if (spot.videos.isNotEmpty)
                    _buildVideoSection(
                      spot,
                      isDark,
                      primaryColor,
                      subtextColor,
                      borderColor,
                      cardHeaderBg,
                    ),

                  // Image Gallery
                  if (spot.hasImages())
                    _buildImageGallery(
                      spot,
                      isDark,
                      primaryColor,
                      borderColor,
                      cardHeaderBg,
                    ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(context, isDark, primaryColor),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Cards (same as before but using spot.ownerName etc.) ----------

  Widget _buildOwnerCard(
    String ownerName,
    String ownerPhone,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Taarifa za Mwenye Nyumba',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person,
                  'Jina la Mwenye Nyumba',
                  ownerName,
                  false,
                  null,
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.phone_rounded,
                  'Namba ya Simu',
                  ownerPhone,
                  ownerPhone != "Hajabainishwa",
                  () async {
                    if (ownerPhone != "Hajabainishwa") {
                      final uri = Uri.parse('tel:$ownerPhone');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                  isDark,
                  primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isClickable,
    VoidCallback? onTap,
    bool isDark,
    Color primaryColor,
  ) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isClickable
                        ? primaryColor
                        : (isDark ? Colors.white : Colors.black87),
                    decoration: isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Anwani ya Nyumba',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (spot.street.isNotEmpty)
                  _buildAddressRow('Mtaa', spot.street, isDark),
                if (spot.ward.isNotEmpty) ...[
                  if (spot.street.isNotEmpty) const SizedBox(height: 8),
                  _buildAddressRow('Kata', spot.ward, isDark),
                ],
                if (spot.district.isNotEmpty) ...[
                  if (spot.ward.isNotEmpty || spot.street.isNotEmpty)
                    const SizedBox(height: 8),
                  _buildAddressRow('Wilaya', spot.district, isDark),
                ],
                if (spot.region.isNotEmpty) ...[
                  if (spot.district.isNotEmpty) const SizedBox(height: 8),
                  _buildAddressRow('Mkoa', spot.region, isDark),
                ],
                if (spot.village.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 14,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kijiji: ${spot.village}',
                          style: TextStyle(fontSize: 12, color: subtextColor),
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
    );
  }

  Widget _buildAddressRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ': $value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.money_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Maelezo ya Bei',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.attach_money_rounded,
                            color: primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Kodi ya Mwezi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      spot.formattedPrice,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                if (spot.hasDeposit()) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Deposit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'sw_TZ',
                          symbol: 'TZS ',
                          decimalDigits: 0,
                        ).format(spot.depositAmount!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
                if (spot.getIncludedAmenities().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Huduma Zilizojumuishwa:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spot.getIncludedAmenities().map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              amenity == 'Maji'
                                  ? Icons.water_drop
                                  : amenity == 'Umeme'
                                  ? Icons.flash_on
                                  : Icons.wifi,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.build_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Vipengele vya Nyumba',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFeatureChip(
                  'Fansi',
                  spot.hasCeiling,
                  Icons.roofing,
                  isDark,
                  primaryColor,
                ),
                _buildFeatureChip(
                  'Aluminiam',
                  spot.hasAluminium,
                  Icons.window_rounded,
                  isDark,
                  primaryColor,
                ),
                _buildFeatureChip(
                  'Ceiling Board',
                  spot.hasCeilingBoard,
                  Icons.grid_on_rounded,
                  isDark,
                  primaryColor,
                ),
                _buildFeatureChip(
                  'Tiles',
                  spot.hasTiles,
                  Icons.square_foot_rounded,
                  isDark,
                  primaryColor,
                ),
                _buildFeatureChip(
                  'Fence / Uzio',
                  spot.hasFence,
                  Icons.fence_rounded,
                  isDark,
                  primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(
    String label,
    bool isAvailable,
    IconData icon,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? primaryColor.withValues(alpha: 0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? primaryColor.withValues(alpha: 0.3)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isAvailable
                ? primaryColor
                : (isDark ? Colors.grey[500] : Colors.grey[400]),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isAvailable
                  ? primaryColor
                  : (isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(
    RentalSpot spot,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Maelezo Kamili ya Nyumba',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              spot.description.isNotEmpty
                  ? spot.description
                  : "Hakuna maelezo ya ziada yaliyotolewa na mwenye nyumba.",
              style: TextStyle(fontSize: 15, color: textColor, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.place_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Vitu vilivyo karibu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: spot.getNearbyAmenitiesList().map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenity,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.video_collection_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Video za Nyumba',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: spot.videos.length,
                itemBuilder: (context, index) {
                  final videoUrl = spot.videos[index];
                  final thumbnail = (spot.videoThumbnails.length > index)
                      ? spot.videoThumbnails[index]
                      : null;
                  return GestureDetector(
                    onTap: () => _playVideo(context, videoUrl),
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (thumbnail != null)
                              CachedNetworkImage(
                                imageUrl: thumbnail,
                                fit: BoxFit.cover,
                                width: 150,
                                height: 210,
                                placeholder: (_, _) => Container(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.videocam_rounded,
                                    size: 54,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.12),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white70),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.movie_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Video ${index + 1}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color borderColor,
    Color cardHeaderBg,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardHeaderBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Picha za Nyumba',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: spot.images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        _showFullScreenImage(context, spot.images, index),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: spot.images[index],
                          fit: BoxFit.cover,
                          width: 140,
                          height: 120,
                          placeholder: (_, _) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: isDark ? Colors.grey[600] : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      children: [
        Text(
          'WASILIANA NA MWENYE NYUMBA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              Icons.call,
              "Piga Simu",
              Colors.green,
              isDark,
              () async {
                if (spot.phone.isNotEmpty) {
                  final uri = Uri.parse('tel:${spot.phone}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                } else {
                  _showErrorSnackBar(context, 'Hakuna namba ya simu');
                }
              },
              primaryColor,
            ),
            _actionButton(Icons.message, "SMS", Colors.blue, isDark, () async {
              if (spot.phone.isNotEmpty) {
                final uri = Uri.parse('sms:${spot.phone}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              } else {
                _showErrorSnackBar(context, 'Hakuna namba ya simu');
              }
            }, primaryColor),
            _actionButton(
              Icons.directions,
              "Eneo",
              Colors.orange,
              isDark,
              () async {
                if (spot.hasValidLocation()) {
                  final uri = Uri.parse(spot.getDirectionsUrl());
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                } else {
                  _showErrorSnackBar(context, 'Hakuna eneo la nyumba');
                }
              },
              primaryColor,
            ),
            _actionButton(
              Icons.share,
              "Sambaza",
              Colors.teal,
              isDark,
              () async {
                final text = spot.getWhatsAppShareText();
                final uri = Uri.parse(
                  'https://wa.me/?text=${Uri.encodeComponent(text)}',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (!context.mounted) return;
                  _showErrorSnackBar(context, 'Haiwezekani kusambaza');
                }
              },
              primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    bool isDark,
    VoidCallback onTap,
    Color primaryColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.5 : 0.3),
              ),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// 🔥 NEW: Video Player Dialog using video_player package
class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _togglePlayback() {
    if (!_isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: GestureDetector(
        onTap: _togglePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else if (_hasError)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Video imeshindwa kufunguka. Jaribu tena baadae.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Funga',
              ),
            ),
            if (_isInitialized && !_controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 92,
                ),
              ),
            if (_isInitialized)
              Positioned(
                right: 16,
                bottom: 76,
                child: Column(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      onPressed: _togglePlayback,
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      onPressed: _toggleMute,
                      icon: Icon(
                        _isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isInitialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF4CAF50),
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
