// lib/screen/rental_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:serkapp/pages/image_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../model/rental_model.dart';

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
                    child: ImageHelper.buildImage(
                      images[index],
                      fit: BoxFit.contain,
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
                    child: ValueListenableBuilder(
                      valueListenable: ValueNotifier<int>(initialIndex),
                      builder: (context, currentIndex, _) {
                        return Text(
                          '${currentIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maelezo ya Nyumba',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== HEADER IMAGE ==========
            GestureDetector(
              onTap: spot.hasImages()
                  ? () => _showFullScreenImage(context, spot.images, 0)
                  : null,
              child: Container(
                height: 280,
                width: double.infinity,
                color: Colors.grey[200],
                child: spot.hasImages()
                    ? ClipRRect(
                        child: ImageHelper.buildImage(
                          spot.images[0],
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.home_rounded,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== JINA LA NYUMBA ==========
                  Text(
                    spot.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ========== ANWANI KAMILI (KISWAHILI) ==========
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spot.getFullSwahiliAddress(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ========== PRICE SECTION ==========
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kodi ya Mwezi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  spot.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                spot.type,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Deposit if available
                        if (spot.hasDeposit()) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.savings,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Deposit: ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'sw_TZ',
                                  symbol: 'TZS ',
                                  decimalDigits: 0,
                                ).format(spot.depositAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Amenities included
                        if (spot.getIncludedAmenities().isNotEmpty) ...[
                          const Divider(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: spot.getIncludedAmenities().map((
                              amenity,
                            ) {
                              return Chip(
                                label: Text(amenity),
                                backgroundColor: Colors.white,
                                avatar: Icon(
                                  amenity == 'Maji'
                                      ? Icons.water_drop
                                      : amenity == 'Umeme'
                                      ? Icons.flash_on
                                      : Icons.wifi,
                                  size: 16,
                                  color: const Color(0xFF2E7D32),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ========== TAARIFA ZA MWENYE NYUMBA ==========
                  const Text(
                    'Taarifa za Mwenye Nyumba',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFF2E7D32),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot.getFullOwnerName(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                spot.phone,
                                style: const TextStyle(fontSize: 15),
                              ),
                              if (spot.altPhone != null &&
                                  spot.altPhone!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    spot.altPhone!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ========== MAELEZO YA NYUMBA (DETAILS) ==========
                  const Text(
                    'Maelezo ya Nyumba',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.bed_rounded,
                          'Vyumba vya Kulala',
                          '${spot.bedrooms}',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.category_rounded,
                          'Aina ya Nyumba',
                          spot.type,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.check_circle_rounded,
                          'Hali',
                          spot.status,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ========== VITU VILIVYO KARIBU ==========
                  if (spot.getNearbyAmenitiesList().isNotEmpty) ...[
                    const Text(
                      'Vitu vilivyo karibu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: spot.getNearbyAmenitiesList().map((amenity) {
                          return Chip(
                            label: Text(amenity),
                            backgroundColor: Colors.white,
                            avatar: const Icon(
                              Icons.place,
                              size: 16,
                              color: Colors.blue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ========== 📝 MAELEZO ZAIDI (DESCRIPTION) ==========
                  const Text(
                    '📝 Maelezo Kamili ya Nyumba',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      spot.description.isNotEmpty
                          ? spot.description
                          : "Hakuna maelezo ya ziada yaliyotolewa na mwenye nyumba.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ========== PICHA ZA NYUMBA (GALLERY) ==========
                  if (spot.hasImages()) ...[
                    const Text(
                      'Picha za Nyumba',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: spot.images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              spot.images,
                              index,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ImageHelper.buildImage(
                                  spot.images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ========== ACTION BUTTONS ==========
                  _buildActionButtons(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        const Text(
          'WASILIANA NA MWENYE NYUMBA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(Icons.call, "Piga Simu", Colors.green, () async {
              final Uri uri = Uri.parse('tel:${spot.phone}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                _showErrorSnackBar(context, 'Haiwezekani kupiga simu');
              }
            }),
            _actionButton(Icons.message, "SMS", Colors.blue, () async {
              final Uri uri = Uri.parse('sms:${spot.phone}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                _showErrorSnackBar(context, 'Haiwezekani kufungua SMS');
              }
            }),
            _actionButton(Icons.directions, "Eneo", Colors.orange, () async {
              if (spot.hasValidLocation()) {
                final Uri uri = Uri.parse(spot.getDirectionsUrl());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  _showErrorSnackBar(context, 'Haiwezekani kufungua ramani');
                }
              } else {
                _showErrorSnackBar(context, 'Hakuna eneo la nyumba');
              }
            }),
            _actionButton(Icons.share, "Sambaza", Colors.teal, () async {
              final String text = spot.getWhatsAppShareText();
              final Uri uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(text)}',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                _showErrorSnackBar(context, 'Haiwezekani kusambaza');
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
