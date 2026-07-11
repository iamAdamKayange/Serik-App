import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/pages/house_registration_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class AdminMapPage extends StatefulWidget {
  final HouseData? newlyAddedHouse;

  const AdminMapPage({super.key, this.newlyAddedHouse});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = const LatLng(-6.7924, 39.2083);
  final Set<Marker> _myHousesMarkers = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<HouseData> _myHouses = [];
  String _searchQuery = '';

  int _totalHouses = 0;
  int _availableHouses = 0;
  int _rentedHouses = 0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadMyHouses();
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
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newLatLng(_currentPosition));
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _loadMyHouses() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('📍 Loading houses for landlord from backend...');
      final allUserHouses = await ApiService.getMyHouses();

      final List<HouseData> houses = allUserHouses
          .map((json) => HouseData.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _myHouses = houses;
        _totalHouses = _myHouses.length;
        _availableHouses = _myHouses
            .where((h) => h.status == "Inapatikana")
            .length;
        _rentedHouses = _myHouses
            .where((h) => h.status == "Imekodishwa")
            .length;
      });

      debugPrint('✅ Loaded ${_myHouses.length} houses for this landlord');
      await _loadMarkers();

      if (widget.newlyAddedHouse != null && mounted) {
        _zoomToNewHouse(widget.newlyAddedHouse!);
      }
    } catch (e) {
      debugPrint('❌ Error loading houses: $e');
      setState(() => _isLoading = false);
      _showError("Imeshindwa kupakia nyumba zako: $e");
    }
  }

  Future<void> _zoomToNewHouse(HouseData house) async {
    if (!house.hasValidLocation()) return;
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(house.latitude!, house.longitude!),
          zoom: 17,
        ),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Nyumba yako imesajiliwa kikamilifu!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> loadedMarkers = {};
    for (var house in _filteredHouses()) {
      if (house.hasValidLocation()) {
        final Uint8List icon = await _createAdminMarkerBitmap(
          house.rentPrice.toInt(),
          house.type,
          house.status,
        );
        final Marker marker = Marker(
          markerId: MarkerId(house.id),
          position: LatLng(house.latitude!, house.longitude!),
          icon: BitmapDescriptor.bytes(icon),
          onTap: () => _showHouseBottomSheet(house),
          consumeTapEvents: true,
          anchor: const Offset(0.5, 1.0),
        );
        loadedMarkers.add(marker);
      }
    }
    if (mounted) {
      setState(() {
        _myHousesMarkers.clear();
        _myHousesMarkers.addAll(loadedMarkers);
        _isLoading = false;
      });
    }
  }

  List<HouseData> _filteredHouses() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _myHouses;

    return _myHouses.where((house) {
      final searchableText = [
        house.name,
        house.firstName,
        house.lastName,
        house.phone,
        house.status,
        house.type,
        house.description,
        house.location,
        house.address,
        house.region,
        house.district,
        house.division,
        house.ward,
        house.village,
        house.street,
        house.nearbyAmenities,
        house.formattedPrice,
        house.rentPrice.toStringAsFixed(0),
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  void _searchMyHouses(String query) {
    setState(() => _searchQuery = query);
    _loadMarkers();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _loadMarkers();
  }

  // ---------- Marker drawing (same as before but using updated fields) ----------
  Future<Uint8List> _createAdminMarkerBitmap(
    int price,
    String type,
    String status,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Color markerColor = _getMarkerColor(type);
    final bool isAvailable = status == "Inapatikana";
    const double width = 58;
    const double height = 72;
    const Offset center = Offset(width / 2, 24);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    Path pinPath({double dx = 0, double dy = 0}) {
      return Path()
        ..moveTo(width / 2 + dx, 68 + dy)
        ..cubicTo(45 + dx, 52 + dy, 54 + dx, 41 + dy, 54 + dx, 25 + dy)
        ..cubicTo(54 + dx, 10 + dy, 43 + dx, 1 + dy, 29 + dx, 1 + dy)
        ..cubicTo(15 + dx, 1 + dy, 4 + dx, 10 + dy, 4 + dx, 25 + dy)
        ..cubicTo(
          4 + dx,
          41 + dy,
          13 + dx,
          52 + dy,
          width / 2 + dx,
          68 + dy,
        )
        ..close();
    }

    canvas.drawPath(pinPath(dx: 1.5, dy: 2.5), shadowPaint);
    canvas.drawPath(pinPath(), Paint()..color = markerColor);
    canvas.drawPath(
      pinPath(),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(center, 10.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 6.5, Paint()..color = markerColor);
    canvas.drawCircle(
      const Offset(22, 15),
      4.5,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    final Paint statusPaint = Paint()
      ..color = isAvailable ? Colors.green : Colors.orange;
    canvas.drawCircle(const Offset(43, 13), 5, statusPaint);
    canvas.drawCircle(
      const Offset(43, 13),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final pricePainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    pricePainter.text = TextSpan(
      text: _abbreviatePrice(price),
      style: const TextStyle(
        fontSize: 9.0,
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
    pricePainter.layout(minWidth: 0, maxWidth: width - 10);
    pricePainter.paint(canvas, Offset((width - pricePainter.width) / 2, 42));

    /*
      final Paint starPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(50, 8), 4, starPaint);
    final starPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    starPainter.text = const TextSpan(
      text: "⭐",
      style: TextStyle(fontSize: 7.0, color: Colors.white),
    );
    starPainter.layout(minWidth: 0, maxWidth: 8);
    starPainter.paint(
      canvas,
      Offset(50 - starPainter.width / 2, 8 - starPainter.height / 2),
    );

    */

    final img = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
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

  // ---------- Bottom sheet with real data and edit button ----------
  void _showHouseBottomSheet(HouseData house) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF0D47A1);
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                              border: Border.all(color: primaryColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Nyumba Yangu",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: house.status == "Inapatikana"
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  house.status == "Inapatikana"
                                      ? Icons.check_circle
                                      : Icons.key,
                                  size: 14,
                                  color: house.status == "Inapatikana"
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  house.status,
                                  style: TextStyle(
                                    color: house.status == "Inapatikana"
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Show brand name (jina maarufu) as main title
                      Text(
                        house.firstName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Show house number if exists
                      if (house.lastName.isNotEmpty)
                        Text(
                          "Namba ya Nyumba: ${house.lastName}",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              house.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [
                                    primaryColor.withValues(alpha: 0.15),
                                    surfaceColor,
                                  ]
                                : [
                                    primaryColor.withValues(alpha: 0.1),
                                    Colors.white,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              "💰",
                              "TZS ${NumberFormat('#,###').format(house.rentPrice)}",
                              "Kodi/Mwezi",
                              isDarkMode,
                            ),
                            _buildStatColumn(
                              "🛏️",
                              "${house.bedrooms}",
                              "Vyumba",
                              isDarkMode,
                            ),
                            _buildStatColumn(
                              "📞",
                              house.phone,
                              "Mawasiliano",
                              isDarkMode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Video section
                      if (house.videos.isNotEmpty) ...[
                        Text(
                          'Video za Nyumba:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: house.videos.length,
                            itemBuilder: (context, index) {
                              final videoUrl = house.videos[index];
                              final thumbnail =
                                  (house.videoThumbnails.isNotEmpty &&
                                      index < house.videoThumbnails.length)
                                  ? house.videoThumbnails[index]
                                  : null;
                              return GestureDetector(
                                onTap: () => _playVideo(videoUrl),
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black,
                                    image: thumbnail != null
                                        ? DecorationImage(
                                            image: NetworkImage(thumbnail),
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
                        const SizedBox(height: 16),
                      ],

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip(
                            house.type,
                            _getMarkerColor(house.type),
                          ),
                          if (house.depositAmount != null &&
                              house.depositAmount! > 0)
                            _buildDetailChip(
                              "Deposit: TZS ${NumberFormat('#,###').format(house.depositAmount)}",
                              Colors.grey,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (house.description.isNotEmpty) ...[
                        Text(
                          "Maelezo:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          house.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _editHouse(house);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: Text(context.tr('Hariri', en: 'Edit')),
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
                              onPressed: () {
                                Navigator.pop(context);
                                _addNewHouse();
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: Text(context.tr('Sajili Nyingine', en: 'Register Another')),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _playVideo(String videoUrl) async {
    final Uri uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Haikuweza kufungua video.', en: 'Could not open video.'))),
      );
    }
  }

  Widget _buildStatColumn(
    String icon,
    String value,
    String label,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  // ---------- Edit functionality - pass existing house to form ----------
  void _editHouse(HouseData house) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseRegistrationForm(
          existingHouse: house,
          onHouseAdded: (updatedHouse) {
            _loadMyHouses(); // refresh after edit
          },
        ),
      ),
    );
    if (result == true) _loadMyHouses();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------- UI Build ----------
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF0D47A1);
    Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : Colors.grey[50]!;
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Ramani Yangu",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadMyHouses,
          ),
        ],
      ),
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
            markers: _myHousesMarkers,
            onMapCreated: (GoogleMapController controller) =>
                _controller.complete(controller),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 210,
              bottom: 20,
            ),
            style: isDarkMode ? _getDarkMapStyle() : null,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildStatsHeader(isDarkMode, primaryColor, surfaceColor),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 126,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceColor,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: context.tr('Tafuta nyumba yako, eneo, bei...', en: 'Search your house, area, price...'),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                      onChanged: _searchMyHouses,
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
          if (!_isLoading && _myHouses.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 192,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_myHousesMarkers.length} / ${_myHouses.length} nyumba',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: surfaceColor,
              foregroundColor: primaryColor,
              elevation: 4,
              mini: true,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            bottom: 170,
            right: 16,
            child: FloatingActionButton(
              onPressed: _loadMyHouses,
              backgroundColor: surfaceColor,
              foregroundColor: primaryColor,
              elevation: 4,
              mini: true,
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
                ),
              ),
            ),
          if (!_isLoading && _myHouses.isEmpty)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 80,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Hujasajili nyumba yoyote",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Bonyeza kitufe cha '+' kuongeza nyumba yako ya kwanza",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _addNewHouse,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(context.tr('Sajili Nyumba Mpya', en: 'Register New House')),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isLoading && _myHouses.isNotEmpty)
            Positioned(
              bottom: 240,
              right: 16,
              child: FloatingActionButton(
                onPressed: _addNewHouse,
                backgroundColor: primaryColor,
                child: const Icon(Icons.add_rounded, color: Colors.white),
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

  Widget _buildStatsHeader(
    bool isDarkMode,
    Color primaryColor,
    Color surfaceColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.map_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nyumba Zangu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      "Angalia nyumba zako kwenye ramani",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$_totalHouses",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStatCard(
                Icons.check_circle_rounded,
                "$_availableHouses",
                "Inapatikana",
                Colors.green,
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildMiniStatCard(
                Icons.key_rounded,
                "$_rentedHouses",
                "Imekodishwa",
                Colors.orange,
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildMiniStatCard(
                Icons.monetization_on_rounded,
                _getTotalIncome(),
                "Mapato",
                Colors.blue,
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTotalIncome() {
    double total = 0;
    for (var house in _myHouses) {
      if (house.status == "Imekodishwa") {
        total += house.rentPrice;
      }
    }
    return "TZS ${(total / 1000).toStringAsFixed(0)}K";
  }

  void _addNewHouse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseRegistrationForm(
          onHouseAdded: (newHouse) {
            _loadMyHouses();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}


