import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/pages/register_page.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/services/realtime_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:serik/config/map_config.dart';
import 'package:serik/pages/mapbox_property_map_page.dart';

// Maeneo ya vyuo – yanaweza kubadilishwa kuwa dynamic kutoka API (kwa sasa ni static)
const List<Map<String, dynamic>> universities = [
  {'name': 'UDOM', 'lat': -6.21630, 'lng': 35.7419, 'radius_km': 1.5},
  {'name': 'UDSM', 'lat': -6.7816, 'lng': 39.20567, 'radius_km': 2.0},
  {'name': 'MUST', 'lat': -8.909401, 'lng': 33.460773, 'radius_km': 1.0},
  {'name': 'DIT', 'lat': -6.8144, 'lng': 39.2833, 'radius_km': 1.2},
  {'name': 'CBE', 'lat': -6.1736, 'lng': 35.7410, 'radius_km': 1.5},
  {'name': 'SUA', 'lat': -6.6999, 'lng': 36.6936, 'radius_km': 1.8},
  {'name': 'IFM', 'lat': -6.81395, 'lng': 39.29366, 'radius_km': 1.3},
];

class CustomMapPage extends StatefulWidget {
  final String? selectedUniversity;
  const CustomMapPage({super.key, this.selectedUniversity});

  @override
  State<CustomMapPage> createState() => _CustomMapPageState();
}

class _CustomMapPageState extends State<CustomMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = const LatLng(-6.7924, 39.2083);
  final Set<Marker> _markers = {};
  final Set<Marker> _universityMarkers = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late final RealtimeCallback _houseChangeListener;

  double _minPrice = 0;
  double _maxPrice = 1000000;
  String _selectedType = 'Zote';
  String _selectedUniversity = 'Zote';

  List<RentalSpot> _rentalSpots = []; // data halisi kutoka API

  bool get isDarkMode =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  Color get primaryColor =>
      isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get surfaceColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subtextColor => isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get searchBarBg => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get loadingBg => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLng = (lng2 - lng1) * (pi / 180);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  bool _isNearUniversity(RentalSpot spot, Map<String, dynamic> university) {
    if (!spot.hasValidLocation()) return false;
    double distance = _calculateDistance(
      university['lat'],
      university['lng'],
      spot.latitude,
      spot.longitude,
    );
    return distance <= university['radius_km'];
  }

  List<RentalSpot> _filterByUniversity(List<RentalSpot> spots, String uniName) {
    if (uniName == 'Zote') return spots;
    final university = universities.firstWhere(
      (u) => u['name'] == uniName,
      orElse: () => {'name': 'Zote', 'lat': 0.0, 'lng': 0.0, 'radius_km': 0.0},
    );
    if (university['name'] == 'Zote') return spots;
    return spots.where((spot) => _isNearUniversity(spot, university)).toList();
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadRentalSpotsFromAPI();
    _houseChangeListener = (_) {
      if (!mounted) return;
      _loadRentalSpotsFromAPI();
    };
    RealtimeService.instance.on('house:changed', _houseChangeListener);
    if (widget.selectedUniversity != null) {
      _selectedUniversity = widget.selectedUniversity!;
    }
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );
        if (mounted) {
          setState(
            () => _currentPosition = LatLng(
              position.latitude,
              position.longitude,
            ),
          );
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition));
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  // ---------- LOAD REAL DATA FROM BACKEND ----------
  Future<void> _loadRentalSpotsFromAPI() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('📍 Loading houses from backend...');
      final List<dynamic> housesJson = await ApiService.getAllHouses();
      debugPrint('✅ Loaded ${housesJson.length} houses from database');

      final List<RentalSpot> spots = housesJson.map((json) {
        final houseData = HouseData.fromJson(json as Map<String, dynamic>);
        return RentalSpot.fromHouseData(houseData);
      }).toList();

      // Tunaweka tu zile zilizo na viwianishi halali (lat/lng si 0.0)
      final spotsWithLocation = spots
          .where((spot) => spot.hasValidLocation())
          .toList();
      debugPrint('📍 Valid location houses: ${spotsWithLocation.length}');

      setState(() => _rentalSpots = spotsWithLocation);
      await _loadMarkers();
    } catch (e) {
      debugPrint('❌ Error loading houses: $e');
      setState(() => _isLoading = false);

      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        errorMessage = context.tr(
          "Hakuna muunganisho wa mtandao. Tafadhali angalia intaneti yako.",
          en: "No internet connection. Please check your internet.",
        );
      } else if (e.toString().contains('timeout')) {
        errorMessage = context.tr(
          "Muunganisho umechukua muda mrefu. Jaribu tena.",
          en: "Connection took too long. Please try again.",
        );
      } else {
        errorMessage = context.tr(
          "Hitilafu katika kupakua nyumba. Jaribu tena baadaye.",
          en: "Error loading houses. Please try again later.",
        );
      }
      _showError(errorMessage);
    }
  }

  Future<void> _loadMarkers() async {
    List<RentalSpot> filteredByUni = _filterByUniversity(
      _rentalSpots,
      _selectedUniversity,
    );
    final Set<Marker> loadedMarkers = {};

    for (var spot in filteredByUni) {
      if (_applyFilters(spot)) {
        // Hakikisha spot ina viwianishi halali kabla ya kuunda marker
        if (!spot.hasValidLocation()) continue;
        final Uint8List icon = await _createCustomMarkerBitmap(
          spot.rentPrice.toInt(),
          spot.type,
        );
        final Marker marker = Marker(
          markerId: MarkerId(spot.id),
          position: LatLng(spot.latitude, spot.longitude),
          icon: BitmapDescriptor.bytes(icon),
          onTap: () => _showPropertyBottomSheet(spot),
          consumeTapEvents: true,
          anchor: const Offset(0.5, 1.0),
        );
        loadedMarkers.add(marker);
      }
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(loadedMarkers);
        _isLoading = false;
      });
    }
    await _addUniversityMarkers();
  }

  bool _applyFilters(RentalSpot spot) {
    if (!spot.hasValidLocation()) return false;
    if (spot.rentPrice < _minPrice || spot.rentPrice > _maxPrice) return false;
    if (_selectedType != 'Zote' && spot.type != _selectedType) return false;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final searchableText = [
        spot.name,
        spot.firstName,
        spot.lastName,
        spot.brandName,
        spot.ownerName,
        spot.houseNumber,
        spot.location,
        spot.address,
        spot.region,
        spot.district,
        spot.division,
        spot.ward,
        spot.village,
        spot.street,
        spot.type,
        spot.status,
        spot.description,
        spot.nearbyAmenities ?? '',
        spot.formattedPrice,
        spot.rentPrice.toStringAsFixed(0),
      ].join(' ').toLowerCase();
      if (!searchableText.contains(query)) {
        return false;
      }
    }
    return true;
  }

  // ---------- University markers (bado static – unaweza kubadilisha kuwa dynamic kwa API) ----------
  Future<void> _addUniversityMarkers() async {
    final Set<Marker> uniMarkers = {};
    for (var uni in universities) {
      final Uint8List icon = await _createUniversityMarkerBitmap(uni['name']);
      final Marker marker = Marker(
        markerId: MarkerId('uni_${uni['name']}'),
        position: LatLng(uni['lat'], uni['lng']),
        icon: BitmapDescriptor.bytes(icon),
        onTap: () => _showUniversityBottomSheet(uni),
        anchor: const Offset(0.5, 0.5),
      );
      uniMarkers.add(marker);
    }
    if (mounted) setState(() => _universityMarkers.addAll(uniMarkers));
  }

  Future<Uint8List> _createUniversityMarkerBitmap(String uniName) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 36;
    final Paint paint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1, borderPaint);
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: uniName.substring(0, min(3, uniName.length)),
      style: const TextStyle(
        fontSize: 10.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: size);
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );
    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void _showUniversityBottomSheet(Map<String, dynamic> university) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              university['name'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Radius: ${university['radius_km']} km",
              style: TextStyle(color: subtextColor),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _selectedUniversity = university['name']);
                _refreshMarkers();
              },
              icon: const Icon(Icons.filter_alt),
              label: Text(
                context.tr('Onyesha Nyumba Karibu', en: 'Show Nearby Houses'),
              ),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Marker design (same as original) ----------
  Future<Uint8List> _createCustomMarkerBitmap(int price, String type) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Color markerColor = _getMarkerColor(type);
    const double width = 44;
    const double height = 56;
    const Offset center = Offset(width / 2, 18);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withAlpha(72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    Path pinPath({double dx = 0, double dy = 0}) {
      return Path()
        ..moveTo(width / 2 + dx, 52 + dy)
        ..cubicTo(34 + dx, 40 + dy, 41 + dx, 31 + dy, 41 + dx, 19 + dy)
        ..cubicTo(41 + dx, 8 + dy, 33 + dx, 1 + dy, 22 + dx, 1 + dy)
        ..cubicTo(11 + dx, 1 + dy, 3 + dx, 8 + dy, 3 + dx, 19 + dy)
        ..cubicTo(3 + dx, 31 + dy, 10 + dx, 40 + dy, width / 2 + dx, 52 + dy)
        ..close();
    }

    canvas.drawPath(pinPath(dx: 1.5, dy: 2.5), shadowPaint);
    canvas.drawPath(pinPath(), Paint()..color = markerColor);
    canvas.drawPath(
      pinPath(),
      Paint()
        ..color = Colors.white.withAlpha(70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(center, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 5.2, Paint()..color = markerColor);
    canvas.drawCircle(
      const Offset(17, 11),
      3.5,
      Paint()..color = Colors.white.withAlpha(115),
    );

    final iconPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    iconPainter.text = TextSpan(
      text: _getPropertyIcon(type),
      style: const TextStyle(
        fontSize: 6.5,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    iconPainter.layout(minWidth: 0, maxWidth: 12);
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    final pricePainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    pricePainter.text = TextSpan(
      text: _abbreviatePrice(price),
      style: const TextStyle(
        fontSize: 7.5,
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
    pricePainter.layout(minWidth: 0, maxWidth: width - 8);
    pricePainter.paint(canvas, Offset((width - pricePainter.width) / 2, 32));

    final img = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  String _getPropertyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return '🏢';
      case 'nyumba ya kawaida':
        return '🏠';
      case 'studio':
        return '📐';
      case 'mansion':
        return '🏛️';
      case 'hostel':
        return '🛏️';
      case 'ghorofa':
        return '🏗️';
      case 'biashara':
        return '🏪';
      default:
        return '🏠';
    }
  }

  String _abbreviatePrice(int price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }

  Color _getMarkerColor(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return const Color(0xFF2196F3);
      case 'nyumba ya kawaida':
        return const Color(0xFF4CAF50);
      case 'studio':
        return const Color(0xFFFF9800);
      case 'mansion':
        return const Color(0xFF9C27B0);
      case 'hostel':
        return const Color(0xFF795548);
      case 'ghorofa':
        return const Color(0xFFE91E63);
      case 'biashara':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF607D8B);
    }
  }

  // ---------- Filter bottom sheet (same as original) ----------

  // ---------- Property Bottom Sheet (imebadilishwa kidogo kuonyesha data halisi) ----------
  void _showPropertyBottomSheet(RentalSpot spot) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isLoggedIn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: isLoggedIn
            ? MediaQuery.of(context).size.height * 0.75
            : MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: isLoggedIn ? 200 : 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      child: spot.hasImages()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: spot.getFirstImage()!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, _) => Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.home_rounded,
                                size: 50,
                                color: isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      spot.brandName, // jina maarufu
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMarkerColor(spot.type).withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        spot.type,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getMarkerColor(spot.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Video section
                    if (spot.videos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Video za Nyumba:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: spot.videos.length,
                          itemBuilder: (context, index) {
                            final videoUrl = spot.videos[index];
                            final hasThumbnail =
                                spot.videoThumbnails.length > index;
                            return GestureDetector(
                              onTap: () => _playVideo(videoUrl),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.black,
                                  image: hasThumbnail
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            spot.videoThumbnails[index],
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      size: 50,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Video',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Owner preview
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mwenye Nyumba',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtextColor,
                                  ),
                                ),
                                Text(
                                  spot.ownerName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price & Bedrooms
                    Row(
                      children: [
                        Expanded(
                          child: isLoggedIn
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.green[900]
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.money_rounded,
                                        color: primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        spot.formattedPrice,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                      ),
                                      Text(
                                        '/mwezi',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildLockedPreviewCard(
                                  Icons.money_rounded,
                                  context.tr(
                                    'Bei imefichwa',
                                    en: 'Price hidden',
                                  ),
                                  context.tr(
                                    'Ingia kuona kodi',
                                    en: 'Sign in to view rent',
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.blue[900]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.bed_rounded,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${spot.bedrooms}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  'vyumba',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    if (isLoggedIn)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: subtextColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              spot.getFormattedAddress(),
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      _buildLockedPreviewCard(
                        Icons.location_on_rounded,
                        context.tr('Eneo limefichwa', en: 'Location hidden'),
                        context.tr(
                          'Ingia kuona anwani ya nyumba',
                          en: 'Sign in to view the address',
                        ),
                      ),
                    const SizedBox(height: 20),

                    if (isLoggedIn) ...[
                      if (spot.hasAnyFeature) ...[
                        Text(
                          'Vipengele vya Nyumba:',
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
                          children: spot
                              .getAllHouseFeatures()
                              .map(
                                (feature) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.green[900]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.green[800]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Namba ya Simu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtextColor,
                                    ),
                                  ),
                                  Text(
                                    spot.phone,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final uri = Uri.parse('tel:${spot.phone}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: Icon(
                                Icons.call,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (spot.hasDeposit())
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.orange[900]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.savings_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Deposit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subtextColor,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'sw_TZ',
                                        symbol: 'TZS ',
                                        decimalDigits: 0,
                                      ).format(spot.depositAmount!),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (spot.hasDeposit()) const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToFullDetails(spot);
                              },
                              icon: const Icon(Icons.info_outline_rounded),
                              label: Text(
                                context.tr(
                                  'Maelezo Kamili',
                                  en: 'Full Details',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse('tel:${spot.phone}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.phone_rounded),
                              label: Text(context.tr('Piga Simu', en: 'Call')),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // haijeingia – onyesha ujumbe wa kuingia
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 40,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Maelezo Kamili Yamefungwa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ingia ili kuona namba ya simu, maelezo kamili na vipengele vya nyumba',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showLoginDialog(spot);
                                },
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  context.tr(
                                    'Ingia Ili Kuona Zaidi',
                                    en: 'Sign in to See More',
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '🔒 Maelezo kamili yanahitaji kuingia',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Dialog and helpers ----------
  void _showLoginDialog(RentalSpot spot) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 54,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Login Required',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unahitaji kuingia ili kuona maelezo kamili ya nyumba hii',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildLockedRow(Icons.phone_rounded, 'Namba ya simu'),
                          const Divider(height: 12),
                          _buildLockedRow(
                            Icons.description_rounded,
                            'Maelezo kamili',
                          ),
                          const Divider(height: 12),
                          _buildLockedRow(
                            Icons.build_rounded,
                            'Vipengele vya nyumba',
                          ),
                          const Divider(height: 12),
                          _buildLockedRow(
                            Icons.attach_money_rounded,
                            'Deposit & fees',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subtextColor,
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(context.tr('Sasa', en: 'Now')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToLogin(spot);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              context.tr('Ingia Sasa', en: 'Sign in Now'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToRegister();
                      },
                      child: Text(
                        'Bado huna akaunti? Jisajili',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildLockedRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: subtextColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
        ),
        Icon(
          Icons.lock,
          size: 14,
          color: isDarkMode ? Colors.grey[600] : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildLockedPreviewCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: subtextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: subtextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.lock_rounded,
            size: 15,
            color: isDarkMode ? Colors.grey[600] : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _playVideo(String videoUrl) async {
    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Haikuweza kufungua video.',
              en: 'Could not open video.',
            ),
          ),
        ),
      );
    }
  }

  void _navigateToFullDetails(RentalSpot spot) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: spot)),
  );
  void _navigateToLogin(RentalSpot spot) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      ).then((_) {
        if (mounted) _refreshMarkers();
      });
  void _navigateToRegister() => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const RegisterPage()),
  );
  void _refreshMarkers() {
    setState(() {
      _markers.clear();
      _isLoading = true;
    });
    _loadMarkers();
  }

  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 1000000;
      _selectedType = 'Zote';
      _selectedUniversity = 'Zote';
      _searchQuery = '';
      _searchController.clear();
    });
    _refreshMarkers();
  }

  void _searchProperties(String query) {
    setState(() => _searchQuery = query);
    _refreshMarkers();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _refreshMarkers();
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Switch between Google Maps and Mapbox based on config
    if (MapConfig.useMapbox) {
      return MapboxPropertyMapPage.browse(
        selectedUniversity: widget.selectedUniversity,
      );
    }
    
    // Original Google Maps implementation
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 12,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: {..._markers, ..._universityMarkers},
            onMapCreated: (controller) => _controller.complete(controller),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 100,
              bottom: 20,
            ),
            style: isDarkMode ? _getDarkMapStyle() : null,
          ),
          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: searchBarBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: context.tr(
                          'Tafuta nyumba, eneo, bei...',
                          en: 'Search houses, area, price...',
                        ),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                      onChanged: _searchProperties,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: primaryColor),
                      onPressed: _clearSearch,
                      tooltip: context.tr('Futa utafutaji', en: 'Clear search'),
                    ),
                ],
              ),
            ),
          ),
          // University filter indicator
          if (_selectedUniversity != 'Zote' && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Karibu na $_selectedUniversity',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedUniversity = 'Zote');
                        _refreshMarkers();
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Counter badge
          if (_markers.isNotEmpty && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nyumba ${_markers.length} zimepatikana',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: searchBarBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: primaryColor),
                onSelected: (value) {
                  switch (value) {
                    case 'location':
                      _determinePosition();
                      break;
                    case 'refresh':
                      _refreshMarkers();
                      break;
                    case 'reset':
                      _resetFilters();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'location',
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(context.tr('Eneo langu', en: 'My location')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(context.tr('Pakia upya', en: 'Refresh')),
                      ],
                    ),
                  ),
                  if ((_selectedType != 'Zote' ||
                      _minPrice > 0 ||
                      _maxPrice < 1000000 ||
                      _selectedUniversity != 'Zote' ||
                      _searchQuery.isNotEmpty))
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          const Icon(Icons.clear_all_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(context.tr('Weka upya', en: 'Reset')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Retry button when no houses and not loading (network error)
          if (!_isLoading && _rentalSpots.isEmpty && _markers.isEmpty)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 60,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange[300]
                            : Colors.orange[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('Imeshindwa kupakia nyumba', en: 'Failed to load houses'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('Tafadhali angalia muunganisho wako wa intaneti', en: 'Please check your internet connection'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtextColor),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _loadRentalSpotsFromAPI(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.tr('Jaribu Tena', en: 'Try Again')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(77),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: loadingBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          "assets/animations/map_loading.json",
                          height: 80,
                          width: 80,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Inapakia nyumba...",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${_rentalSpots.length} nyumba zimepatikana",
                          style: TextStyle(color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDarkMapStyle() => '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
      {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
      {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
      {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
      {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
      {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
      {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
      {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
      {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
      {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
    ]
  ''';

  @override
  void dispose() {
    RealtimeService.instance.off('house:changed', _houseChangeListener);
    _searchController.dispose();
    super.dispose();
  }
}
