// lib/screen/custom_map_page.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:serkapp/model/rental_model.dart';
import 'package:serkapp/pages/image_helper.dart';
import 'package:serkapp/screen/rental_detail_screen.dart';
import 'package:serkapp/services/api_services.dart';

// Vyuo na kuratibu zao
const List<Map<String, dynamic>> universities = [
  {'name': 'UDOM', 'lat': -6.1730, 'lng': 35.7419, 'radius_km': 1.5},
  {'name': 'UDSM', 'lat': -6.7696, 'lng': 39.2410, 'radius_km': 2.0},
  {'name': 'MUST', 'lat': -6.8235, 'lng': 37.6606, 'radius_km': 1.0},
  {'name': 'DIT', 'lat': -6.8160, 'lng': 39.2803, 'radius_km': 1.2},
  {'name': 'MUCE', 'lat': -6.9158, 'lng': 39.2736, 'radius_km': 1.8},
  {'name': 'IFM', 'lat': -6.8230, 'lng': 39.2691, 'radius_km': 1.3},
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

  // Filter options
  double _minPrice = 0;
  double _maxPrice = 1000000;
  String _selectedType = 'Zote';
  String _selectedUniversity = 'Zote';
  final List<String> _propertyTypes = [
    'Zote',
    'Nyumba ya Kawaida',
    'Apartment',
    'Studio',
    'Mansion',
    'Hostel',
    'Ghorofa',
    'Biashara',
  ];

  // 🔥 CHANGED: Use RentalSpot instead of HouseData
  List<RentalSpot> _rentalSpots = [];

  // Hesabu ya umbali (Haversine formula)
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

  // Check kama nyumba iko karibu na chuo (using RentalSpot)
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

  // Filter nyumba kwa chuo (using RentalSpot)
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
    _loadRentalSpotsFromAPI(); // 🔥 CHANGED: Load from API

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
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
        }

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  // 🔥 NEW: Load RentalSpots from API
  Future<void> _loadRentalSpotsFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📍 Loading rental spots from API for map...');

      // Get all rental spots from API
      final spots = await ApiService.getAllRentalSpots();

      debugPrint('✅ Loaded ${spots.length} rental spots from API');

      // Filter only spots with valid coordinates
      final spotsWithLocation = spots
          .where((spot) => spot.hasValidLocation())
          .toList();

      debugPrint(
        '📍 Spots with valid coordinates: ${spotsWithLocation.length}',
      );

      setState(() {
        _rentalSpots = spotsWithLocation;
      });

      await _loadMarkers();
    } catch (e) {
      debugPrint('❌ Error loading rental spots: $e');
      setState(() {
        _isLoading = false;
      });
      _showError("Hitilafu katika kupakua nyumba: $e");
    }
  }

  // 🔥 MODIFIED: Load markers from _rentalSpots
  Future<void> _loadMarkers() async {
    List<RentalSpot> filteredByUni = _filterByUniversity(
      _rentalSpots,
      _selectedUniversity,
    );

    final Set<Marker> loadedMarkers = {};

    for (var spot in filteredByUni) {
      if (_applyFilters(spot)) {
        final Uint8List icon = await _createCustomMarkerBitmap(
          spot.rentPrice.toInt(),
          spot.type,
        );

        final Marker marker = Marker(
          markerId: MarkerId(spot.id),
          position: LatLng(spot.latitude, spot.longitude),
          icon: BitmapDescriptor.bytes(icon),
          onTap: () {
            _showPropertyBottomSheet(spot);
          },
          consumeTapEvents: true,
          anchor: const Offset(0.5, 0.5),
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

  // 🔥 MODIFIED: Apply filters using RentalSpot
  bool _applyFilters(RentalSpot spot) {
    if (!spot.hasValidLocation()) return false;

    if (spot.rentPrice < _minPrice || spot.rentPrice > _maxPrice) {
      return false;
    }

    if (_selectedType != 'Zote' && spot.type != _selectedType) return false;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      if (!spot.name.toLowerCase().contains(query) &&
          !spot.location.toLowerCase().contains(query) &&
          !spot.rentPrice.toString().contains(query) &&
          !spot.type.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  // Kuongeza alama za vyuo kwenye ramani
  Future<void> _addUniversityMarkers() async {
    final Set<Marker> uniMarkers = {};

    for (var uni in universities) {
      final Uint8List icon = await _createUniversityMarkerBitmap(uni['name']);

      final Marker marker = Marker(
        markerId: MarkerId('uni_${uni['name']}'),
        position: LatLng(uni['lat'], uni['lng']),
        icon: BitmapDescriptor.bytes(icon),
        onTap: () {
          _showUniversityBottomSheet(uni);
        },
        anchor: const Offset(0.5, 0.5),
      );
      uniMarkers.add(marker);
    }

    if (mounted) {
      setState(() {
        _universityMarkers.clear();
        _universityMarkers.addAll(uniMarkers);
      });
    }
  }

  // Create marker bitmap kwa vyuo
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
      textDirection: TextDirection.ltr,
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

  // Bottom sheet kwa vyuo
  void _showUniversityBottomSheet(Map<String, dynamic> university) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                university['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Radius: ${university['radius_km']} km"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedUniversity = university['name'];
                        });
                        _refreshMarkers();
                      },
                      icon: const Icon(Icons.filter_alt),
                      label: const Text("Onyesha Nyumba Karibu"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List> _createCustomMarkerBitmap(int price, String type) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Color markerColor = _getMarkerColor(type);

    const double width = 80;
    const double height = 40;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, width, height),
        const Radius.circular(10),
      ),
      shadowPaint,
    );

    final Paint paint = Paint()..color = markerColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(10),
      ),
      paint,
    );

    final pricePainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    pricePainter.text = TextSpan(
      text: _abbreviatePrice(price),
      style: const TextStyle(
        fontSize: 10.0,
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );

    pricePainter.layout(minWidth: 0, maxWidth: width);
    pricePainter.paint(canvas, Offset((width - pricePainter.width) / 2, 6));

    final typePainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    typePainter.text = TextSpan(
      text: _abbreviateType(type),
      style: const TextStyle(
        fontSize: 8.0,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );

    typePainter.layout(minWidth: 0, maxWidth: width);
    typePainter.paint(canvas, Offset((width - typePainter.width) / 2, 22));

    final img = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  String _abbreviatePrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toString();
  }

  String _abbreviateType(String type) {
    if (type.length > 8) {
      final words = type.split(' ');
      if (words.length > 1) {
        return '${words[0].substring(0, 3)}..';
      }
      return '${type.substring(0, 6)}..';
    }
    return type;
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

  // Filter dialog
  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chagua Vigezo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _resetFilters();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sawazisha',
                            style: TextStyle(color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chuo filter
                          const Text(
                            'Chagua Chuo Karibu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedUniversity,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items:
                                  [
                                    'Zote',
                                    ...universities.map(
                                      (u) => u['name'] as String,
                                    ),
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setStateBottomSheet(() {
                                  _selectedUniversity = newValue!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bei range
                          const Text(
                            'Aina mbalimbali za Bei',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 2000000,
                            divisions: 20,
                            labels: RangeLabels(
                              'TZS ${_minPrice.toInt()}',
                              'TZS ${_maxPrice.toInt()}',
                            ),
                            onChanged: (RangeValues values) {
                              setStateBottomSheet(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                            activeColor: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TZS ${_minPrice.toInt()}'),
                              Text('TZS ${_maxPrice.toInt()}'),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Aina ya nyumba
                          const Text(
                            'Aina ya Nyumba',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _propertyTypes.map((type) {
                              final isSelected = _selectedType == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setStateBottomSheet(() {
                                    _selectedType = type;
                                  });
                                },
                                selectedColor: const Color(0xFF2E7D32),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),

                          // Taarifa ya idadi ya nyumba
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Nyumba ${_markers.length} zimepatikana kutoka kwa ${_rentalSpots.length}',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Button ya kutumia vigezo
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: () {
                                _refreshMarkers();
                                Navigator.pop(context);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Tumia Vigezo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      },
    );
  }

  // 🔥 MODIFIED: Bottom sheet kwa nyumba using RentalSpot with Base64 image support
  void _showPropertyBottomSheet(RentalSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔥 Picha - Now supports Base64 images
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[200],
                        ),
                        child: spot.hasImages()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ImageHelper.buildImage(
                                  spot.getFirstImage()!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.home_rounded,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Jina la nyumba
                      Text(
                        spot.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Anwani (using RentalSpot helper)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spot.getShortAddress(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mwenye nyumba
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF2E7D32),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spot.getFullOwnerName(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    spot.phone,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Maelezo (using RentalSpot helper)
                      Text(
                        spot.getShortDescription(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip(
                            Icons.bed_rounded,
                            "${spot.bedrooms} Vyumba",
                          ),
                          _buildDetailChip(
                            Icons.calendar_today_rounded,
                            "${spot.formattedPrice}/mwezi",
                          ),
                          _buildDetailChip(
                            Icons.check_circle_rounded,
                            spot.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showSuccessMessage(
                                  "Imeongezwa kwenye favorites",
                                );
                              },
                              icon: const Icon(Icons.favorite_border_rounded),
                              label: const Text('Weka Favoriti'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(
                                  color: Color(0xFF2E7D32),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                _showRentalDetails(spot);
                              },
                              icon: const Icon(Icons.phone_rounded),
                              label: const Text('Piga Simu'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Button ya maelezo kamili
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showRentalDetails(spot);
                          },
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text('Angalia Maelezo Kamili'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 MODIFIED: Show rental details using RentalSpot directly
  void _showRentalDetails(RentalSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: spot)),
    );
  }

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
    setState(() {
      _searchQuery = query;
    });
    _refreshMarkers();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
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
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 100,
              bottom: 20,
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Tafuta nyumba, eneo, bei...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: _searchProperties,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: Colors.grey[300]),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF2E7D32),
                    ),
                    onPressed: _showFiltersBottomSheet,
                    tooltip: "Chuja",
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
                        setState(() {
                          _selectedUniversity = 'Zote';
                        });
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
                  color: const Color(0xFF2E7D32),
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

          // My Location Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2E7D32),
              elevation: 4,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Refresh Button
          Positioned(
            bottom: 170,
            right: 16,
            child: FloatingActionButton(
              onPressed: _refreshMarkers,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2E7D32),
              elevation: 4,
              mini: true,
              child: const Icon(Icons.refresh_rounded),
            ),
          ),

          // Reset Filters Button
          if ((_selectedType != 'Zote' ||
              _minPrice > 0 ||
              _maxPrice < 1000000 ||
              _selectedUniversity != 'Zote'))
            Positioned(
              bottom: 240,
              right: 16,
              child: FloatingActionButton(
                onPressed: _resetFilters,
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                elevation: 4,
                mini: true,
                child: const Icon(Icons.clear_all_rounded),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        Lottie.asset(
                          "assets/animations/map_loading.json",
                          height: 80,
                          width: 80,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Inapakia nyumba...",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${_rentalSpots.length} nyumba zimepatikana",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // No results message
          if (!_isLoading && _markers.isEmpty && _rentalSpots.isNotEmpty)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      const Icon(
                        Icons.search_off_rounded,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hakuna nyumba zilizopatika",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Chagua vigezo vingine au weka utafutaji tofauti",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _resetFilters,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        child: const Text('Sawazisha Vigezo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // No houses registered message
          if (!_isLoading && _rentalSpots.isEmpty)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      const Icon(
                        Icons.home_work_rounded,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hakuna nyumba zilizosajiliwa",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sajili nyumba yako kwanza kupitia menu ya nyumba",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
