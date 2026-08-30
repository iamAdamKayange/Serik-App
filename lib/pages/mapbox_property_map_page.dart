import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_api/mapbox_api.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:polyline_tools/polyline_tools.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';

/// SERK Navigation Architecture
/// Mapbox → Directions API → Route Data → Mapbox Map + TTS Voice
/// Simple 3-sound system: start, reroute, arrival

const List<Map<String, dynamic>> _universities = [
  {'name': 'UDOM', 'lat': -6.21630, 'lng': 35.7419, 'radius_km': 1.5},
  {'name': 'UDSM', 'lat': -6.7816, 'lng': 39.20567, 'radius_km': 2.0},
  {'name': 'MUST', 'lat': -8.909401, 'lng': 33.460773, 'radius_km': 1.0},
  {'name': 'DIT', 'lat': -6.8144, 'lng': 39.2833, 'radius_km': 1.2},
  {'name': 'CBE', 'lat': -6.1736, 'lng': 35.7410, 'radius_km': 1.5},
  {'name': 'SUA', 'lat': -6.6999, 'lng': 36.6936, 'radius_km': 1.8},
  {'name': 'IFM', 'lat': -6.81395, 'lng': 39.29366, 'radius_km': 1.3},
];

enum PropertyMapMode { browse, landlord }

class MapboxPropertyMapPage extends StatefulWidget {
  final PropertyMapMode mode;
  final String? selectedUniversity;

  const MapboxPropertyMapPage.browse({super.key, this.selectedUniversity})
    : mode = PropertyMapMode.browse;

  const MapboxPropertyMapPage.landlord({super.key})
    : mode = PropertyMapMode.landlord,
      selectedUniversity = null;

  @override
  State<MapboxPropertyMapPage> createState() => _MapboxPropertyMapPageState();
}

class _MapboxPropertyMapPageState extends State<MapboxPropertyMapPage> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _annotationManager;
  mapbox.PolylineAnnotationManager? _polylineManager;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Uint8List> _iconCache = {};

  bool _isLoading = true;
  final bool _isGettingLocation = false;
  double _currentZoom = 12;
  String _searchQuery = '';
  final double _minPrice = 0;
  final double _maxPrice = 1000000;
  String _selectedType = 'Zote';
  String _selectedUniversity = 'Zote';

  // Directions state
  bool _isGettingDirections = false;
  RentalSpot? _selectedPropertyForDirections;
  mapbox.PolylineAnnotation? _routePolyline;
  String _routeDistance = '';
  String _routeDuration = '';
  List<String> _turnByTurnInstructions = [];
  geo.Position? _currentPosition;

  // Real-time navigation state
  List<_RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;
  String _nextTurnInstruction = '';
  StreamSubscription<geo.Position>? _positionStreamSubscription;

  // SERK Navigation state
  bool _isNavigating = false;
  bool _isVoiceEnabled = true;
  double _remainingDistance = 0.0;
  String _currentInstruction = '';
  String _etaTime = '';
  int _lastAnnouncedStepIndex = -1;
  double _lastAnnouncedDistance = 0.0;
  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer;

  // Simple navigation tracking
  DateTime? _lastAnnouncementTime;

  // Current location marker
  mapbox.PointAnnotation? _currentLocationMarker;

  geo.Position get _defaultPosition => geo.Position(
    latitude: -6.7924,
    longitude: 39.2083,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  List<RentalSpot> _spots = [];
  List<_ClusterBucket> _clusters = [];

  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get primaryColor =>
      isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get surfaceColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subtextColor => isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get searchBarBg => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  // Category-based colors for 3D markers
  Color _getMarkerColorForCategory(String type) {
    final lowerType = type.toLowerCase();

    // Red for apartments/flats
    if (lowerType.contains('apartment') || lowerType.contains('flat')) {
      return const Color(0xFFE53935); // Red
    }
    // Blue for shared/bedsitter
    if (lowerType.contains('shared') || lowerType.contains('bedsitter')) {
      return const Color(0xFF1E88E5); // Blue
    }
    // Green for self-container
    if (lowerType.contains('self') || lowerType.contains('container')) {
      return const Color(0xFF43A047); // Green
    }
    // Purple for studio
    if (lowerType.contains('studio')) {
      return const Color(0xFF8E24AA); // Purple
    }
    // Orange for others
    return const Color(0xFFFB8C00); // Orange
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedUniversity != null) {
      _selectedUniversity = widget.selectedUniversity!;
    }
    _loadData();
    _determinePosition();
    _initTts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionStreamSubscription?.cancel();
    _flutterTts?.stop();
    _flutterTts = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();

    try {
      await _flutterTts?.setLanguage('en-US');
      await _flutterTts?.setSpeechRate(0.9);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  /// SERK Navigation Sounds - Simple 3-sound system
  Future<void> _playNavigationSound(String soundType) async {
    if (_audioPlayer == null) return;

    try {
      switch (soundType) {
        case 'navigation_start':
          await _audioPlayer?.play(AssetSource('sounds/navigation_start.mp3'));
          break;
        case 'rerouting':
          await _audioPlayer?.play(AssetSource('sounds/rerouting.mp3'));
          break;
        case 'destination_reached':
          await _audioPlayer?.play(
            AssetSource('sounds/destination_reached.mp3'),
          );
          break;
      }
    } catch (e) {
      debugPrint('Sound playback error: $e');
      // Continue without sound if files not available
    }
  }

  bool _isGpsPositionValid(geo.Position position) {
    // Simple GPS validation
    if (position.accuracy > 50) return false;
    if (position.latitude.abs() > 90 || position.longitude.abs() > 180)
      return false;
    return true;
  }

  /// SERK Voice Navigation - Simple TTS announcements
  Future<void> _speak(String text) async {
    if (!_isVoiceEnabled || _flutterTts == null) return;

    try {
      // Rate limiting (3 seconds between announcements)
      if (_lastAnnouncementTime != null) {
        final timeSinceLast = DateTime.now().difference(_lastAnnouncementTime!);
        if (timeSinceLast.inSeconds < 3) return;
      }

      if (!mounted) return;

      await _flutterTts?.stop();
      await _flutterTts?.speak(text);
      _lastAnnouncementTime = DateTime.now();
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final housesJson = widget.mode == PropertyMapMode.landlord
          ? await ApiService.getMyHouses()
          : await ApiService.getAllHouses();

      final loaded = housesJson
          .map((json) {
            final house = HouseData.fromJson(json as Map<String, dynamic>);
            return RentalSpot.fromHouseData(house);
          })
          .where((spot) => spot.hasValidLocation())
          .toList();

      if (!mounted) return;
      setState(() {
        _spots = widget.mode == PropertyMapMode.browse && !auth.isLandlord
            ? loaded
            : loaded;
        _clusters = _buildClusters(_filterSpots(_spots), _currentZoom);
        _isLoading = false;
      });
      await _refreshAnnotations();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Imeshindwa kupakia nyumba kwenye ramani.',
              en: 'Failed to load houses on the map.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _determinePosition() async {
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always) {
        final position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );
        _currentPosition = position;
        final map = _mapboxMap;
        if (mounted) {
          await map?.setCamera(
            mapbox.CameraOptions(
              center: mapbox.Point(
                coordinates: mapbox.Position(
                  position.longitude,
                  position.latitude,
                ),
              ),
              zoom: 13,
            ),
          );
          await map?.location.updateSettings(
            mapbox.LocationComponentSettings(
              enabled: true,
              pulsingEnabled: true,
              puckBearingEnabled: true,
            ),
          );
          // Add custom location marker
          await _addCurrentLocationMarker(position);
        }
      }
    } catch (_) {}
  }

  Future<void> _addCurrentLocationMarker(geo.Position position) async {
    final manager = _annotationManager;
    if (manager == null) return;

    // Remove existing marker
    if (_currentLocationMarker != null) {
      await manager.delete(_currentLocationMarker!);
    }

    // Create custom location marker bitmap
    final image = await _buildLocationMarkerBitmap();

    // Create annotation
    final annotation = await manager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(position.longitude, position.latitude),
        ),
        image: image,
        iconSize: 1.0,
      ),
    );

    setState(() {
      _currentLocationMarker = annotation;
    });
  }

  Future<Uint8List> _buildLocationMarkerBitmap() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 120.0;

    // Draw outer ring (blue)
    final outerRingPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(size / 2, size / 2), 24, outerRingPaint);

    // Draw inner circle (white)
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), 18, innerCirclePaint);

    // Draw center dot (blue)
    final centerDotPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), 10, centerDotPaint);

    // Draw pointer/shadow below
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size / 2, size / 2 + 28), 8, shadowPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    _polylineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();

    // Set camera bounds for Tanzania/East Africa
    await mapboxMap.setBounds(
      mapbox.CameraBoundsOptions(
        bounds: mapbox.CoordinateBounds(
          southwest: mapbox.Point(coordinates: mapbox.Position(29.0, -12.0)),
          northeast: mapbox.Point(coordinates: mapbox.Position(41.0, -1.0)),
          infiniteBounds: false,
        ),
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
    );

    await mapboxMap.location.updateSettings(
      mapbox.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    await _refreshAnnotations();
  }

  void _onCameraChangeListener(mapbox.CameraChangedEventData data) {
    final zoom = data.cameraState.zoom;
    if ((zoom - _currentZoom).abs() < 0.1) return;
    _currentZoom = zoom;
    _clusters = _buildClusters(_filterSpots(_spots), _currentZoom);
    _refreshAnnotations();
  }

  Future<void> _refreshAnnotations() async {
    final manager = _annotationManager;
    if (manager == null) return;
    final clusters = _buildClusters(_filterSpots(_spots), _currentZoom);
    _clusters = clusters;
    await manager.deleteAll();

    for (final cluster in clusters) {
      final image = await _markerBitmapForCluster(cluster);
      await manager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(cluster.lng, cluster.lat),
          ),
          image: image,
          iconSize: 1.0,
        ),
      );
    }
  }

  List<RentalSpot> _filterSpots(List<RentalSpot> spots) {
    final query = _searchQuery.trim().toLowerCase();
    return spots.where((spot) {
      final matchesSearch =
          query.isEmpty ||
          [
            spot.brandName,
            spot.ownerName,
            spot.houseNumber,
            spot.location,
            spot.address,
            spot.region,
            spot.district,
            spot.ward,
            spot.street,
            spot.type,
            spot.formattedPrice,
          ].join(' ').toLowerCase().contains(query);

      final matchesType = _selectedType == 'Zote' || spot.type == _selectedType;
      final matchesPrice =
          spot.rentPrice >= _minPrice && spot.rentPrice <= _maxPrice;
      final matchesUniversity =
          _selectedUniversity == 'Zote' ||
          _isNearUniversity(spot, _selectedUniversity);
      return matchesSearch && matchesType && matchesPrice && matchesUniversity;
    }).toList();
  }

  bool _isNearUniversity(RentalSpot spot, String universityName) {
    if (universityName == 'Zote') return true;
    final university = _universities.firstWhere(
      (u) => u['name'] == universityName,
      orElse: () => {'name': 'Zote', 'lat': 0.0, 'lng': 0.0, 'radius_km': 0.0},
    );
    if (university['name'] == 'Zote') return true;

    final distance = _distanceKm(
      university['lat'] as double,
      university['lng'] as double,
      spot.latitude,
      spot.longitude,
    );
    return distance <= (university['radius_km'] as double);
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  List<_ClusterBucket> _buildClusters(List<RentalSpot> spots, double zoom) {
    final grid = _gridSizeForZoom(zoom);
    final buckets = <String, List<RentalSpot>>{};

    for (final spot in spots) {
      final x = (spot.longitude / grid).floor();
      final y = (spot.latitude / grid).floor();
      final key = '$x:$y';
      buckets.putIfAbsent(key, () => []).add(spot);
    }

    return buckets.values.map((items) {
      final lat =
          items.fold<double>(0, (sum, spot) => sum + spot.latitude) /
          items.length;
      final lng =
          items.fold<double>(0, (sum, spot) => sum + spot.longitude) /
          items.length;
      return _ClusterBucket(lat: lat, lng: lng, spots: items);
    }).toList();
  }

  double _gridSizeForZoom(double zoom) {
    if (zoom >= 17) return 0.003;
    if (zoom >= 16) return 0.006;
    if (zoom >= 15) return 0.012;
    if (zoom >= 14) return 0.02;
    if (zoom >= 13) return 0.04;
    if (zoom >= 12) return 0.06;
    if (zoom >= 11) return 0.1;
    return 0.15;
  }

  Future<Uint8List> _markerBitmapForCluster(_ClusterBucket cluster) async {
    final key = cluster.cacheKey;
    if (_iconCache.containsKey(key)) return _iconCache[key]!;

    final image = await _buildClusterBitmap(
      cluster.spots.length,
      cluster.spots.first.rentPrice,
      cluster.spots.first.type,
    );
    _iconCache[key] = image;
    return image;
  }

  Future<Uint8List> _buildClusterBitmap(
    int count,
    double price,
    String type,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 120.0;
    final isCluster = count > 1;
    final fill = isCluster
        ? const Color(0xFF0F8B61)
        : _getMarkerColorForCategory(type);

    // 3D-style pin body (rounded at top, pointed at bottom)
    var pinPath = Path();
    final pinWidth = isCluster ? 50.0 : 44.0;
    final pinHeight = isCluster ? 70.0 : 64.0;
    final pinX = size / 2;
    final pinY = size / 2 - 10;

    // Draw 3D shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(
      Path()
        ..moveTo(pinX - pinWidth / 2 + 3, pinY - pinHeight / 2 + 3)
        ..lineTo(pinX + pinWidth / 2 + 3, pinY - pinHeight / 2 + 3)
        ..quadraticBezierTo(
          pinX + pinWidth / 2 + 3,
          pinY + pinHeight / 2 + 3,
          pinX + 3,
          pinY + pinHeight / 2 + 3,
        )
        ..lineTo(pinX + 3, pinY + pinHeight + 3)
        ..lineTo(pinX - 3, pinY + pinHeight + 3)
        ..lineTo(pinX - 3, pinY + pinHeight / 2 + 3)
        ..quadraticBezierTo(
          pinX - pinWidth / 2 + 3,
          pinY + pinHeight / 2 + 3,
          pinX - pinWidth / 2 + 3,
          pinY - pinHeight / 2 + 3,
        )
        ..close(),
      shadow,
    );

    // Draw pin body
    final pinPaint = Paint()..color = fill;
    pinPath = Path()
      ..moveTo(pinX - pinWidth / 2, pinY - pinHeight / 2)
      ..lineTo(pinX + pinWidth / 2, pinY - pinHeight / 2)
      ..quadraticBezierTo(
        pinX + pinWidth / 2,
        pinY + pinHeight / 2,
        pinX,
        pinY + pinHeight / 2,
      )
      ..lineTo(pinX, pinY + pinHeight)
      ..lineTo(pinX, pinY + pinHeight / 2)
      ..quadraticBezierTo(
        pinX - pinWidth / 2,
        pinY + pinHeight / 2,
        pinX - pinWidth / 2,
        pinY - pinHeight / 2,
      )
      ..close();

    canvas.drawPath(pinPath, pinPaint);

    // Draw white border (thicker for 3D effect)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white;
    canvas.drawPath(pinPath, borderPaint);

    // Draw inner white circle (like in the image)
    if (!isCluster) {
      final innerCirclePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pinX, pinY - 5), 14, innerCirclePaint);

      // Draw price text inside white circle
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      final label = _formatPrice(price);

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: fill,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size - textPainter.width) / 2, pinY - 10),
      );
    } else {
      // For clusters, draw count text in white
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      final label = '$count';

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size - textPainter.width) / 2, pinY - 8),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    }
    return price.toStringAsFixed(0);
  }

  Future<void> _handleTap(mapbox.MapContentGestureContext context) async {
    final tappedLat = context.point.coordinates.lat;
    final tappedLng = context.point.coordinates.lng;
    final clusters = _buildClusters(_filterSpots(_spots), _currentZoom);
    if (clusters.isEmpty) return;

    final nearest =
        clusters
            .map(
              (cluster) => (
                cluster: cluster,
                distance: _distanceKm(
                  tappedLat.toDouble(),
                  tappedLng.toDouble(),
                  cluster.lat,
                  cluster.lng,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));

    final closest = nearest.first;
    if (closest.distance > 0.8) return;

    if (closest.cluster.spots.length > 1) {
      await _mapboxMap?.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              closest.cluster.lng,
              closest.cluster.lat,
            ),
          ),
          zoom: (_currentZoom + 2).clamp(12, 18),
        ),
      );
      return;
    }

    if (!mounted) return;
    _showPropertyDetails(closest.cluster.spots.first);
  }

  void _showPropertyDetails(RentalSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: spot.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: spot.images.first,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 88,
                            height: 88,
                            color: primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.home_rounded,
                              color: primaryColor,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.brandName.isNotEmpty
                              ? spot.brandName
                              : spot.ownerName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spot.getShortAddress(),
                          style: TextStyle(color: subColor, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          spot.formattedPrice,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _getDirections(spot);
                      },
                      icon: _isGettingDirections
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        _isGettingDirections
                            ? context.tr('Inapata...', en: 'Getting route...')
                            : context.tr('Njia', en: 'Directions'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RentalDetailScreen(spot: spot),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open'),
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

  void _setUniversity(String value) {
    setState(() {
      _selectedUniversity = value;
    });
    _refreshAnnotations();
  }

  List<RentalSpot> _visibleSpots() => _filterSpots(_spots);

  /// SERK Navigation UI - Clean and simple overlay
  Widget _buildNavigationOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          // Top instruction - Clean Google Maps style
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Turn icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getTurnIcon(), color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  // Instruction
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDistance(_remainingDistance),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          _currentInstruction,
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  // ETA
                  Text(
                    'ETA: $_etaTime',
                    style: TextStyle(fontSize: 14, color: subtextColor),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom controls
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Exit button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopNavigation,
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('Sitisha', en: 'Exit')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Voice toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isVoiceEnabled = !_isVoiceEnabled;
                      });
                    },
                    icon: Icon(
                      _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTurnIcon() {
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) {
      return Icons.location_on;
    }

    final modifier = _routeSteps[_currentStepIndex].modifier;
    if (modifier == null) return Icons.arrow_upward;

    switch (modifier) {
      case NavigationManeuverModifier.LEFT:
        return Icons.turn_left;

      case NavigationManeuverModifier.RIGHT:
        return Icons.turn_right;

      case NavigationManeuverModifier.SLIGHT_LEFT:
        return Icons.turn_slight_left;

      case NavigationManeuverModifier.SLIGHT_RIGHT:
        return Icons.turn_slight_right;

      case NavigationManeuverModifier.SHARP_LEFT:
        return Icons.keyboard_double_arrow_left;

      case NavigationManeuverModifier.SHARP_RIGHT:
        return Icons.keyboard_double_arrow_right;

      case NavigationManeuverModifier.UTURN:
        return Icons.u_turn_left;

      case NavigationManeuverModifier.STRAIGHT:
        return Icons.arrow_upward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _visibleSpots().length;
    final initialCenter = _spots.isNotEmpty
        ? mapbox.Position(_spots.first.longitude, _spots.first.latitude)
        : mapbox.Position(
            _defaultPosition.longitude,
            _defaultPosition.latitude,
          );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Map fills entire available space
          Positioned.fill(
            child: mapbox.MapWidget(
              key: ValueKey('mapbox-property-map-$isDarkMode'),
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(coordinates: initialCenter),
                zoom: 12,
              ),
              styleUri: isDarkMode
                  ? mapbox.MapboxStyles.DARK
                  : mapbox.MapboxStyles.MAPBOX_STREETS,
              textureView: true,
              onMapCreated: _onMapCreated,
              onCameraChangeListener: _onCameraChangeListener,
              onTapListener: _handleTap,
            ),
          ),

          // Navigation overlay (when actively navigating)
          if (_isNavigating) _buildNavigationOverlay(),
          // Floating compact header area
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Compact title row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.mode == PropertyMapMode.landlord
                              ? context.tr(
                                  'Ramani ya Nyumba Zangu',
                                  en: 'My Houses Map',
                                )
                              : context.tr(
                                  'Ramani ya Nyumba',
                                  en: 'Property Map',
                                ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _determinePosition,
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Floating compact search bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: searchBarBg.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: subtextColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _refreshAnnotations();
                          },
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: context.tr(
                              'Tafuta nyumba...',
                              en: 'Search houses...',
                            ),
                            hintStyle: TextStyle(
                              color: subtextColor,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: primaryColor,
                            size: 14,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _refreshAnnotations();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Compact horizontal filter row
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCompactFilterChip('Zote'),
                      const SizedBox(width: 4),
                      _buildCompactFilterChip('self_container'),
                      const SizedBox(width: 4),
                      _buildCompactFilterChip('shared'),
                      const SizedBox(width: 4),
                      _buildCompactFilterChip('bedsitter'),
                      const SizedBox(width: 4),
                      _buildCompactFilterChip('studio'),
                      const SizedBox(width: 4),
                      _buildCompactFilterChip('flat'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Compact stats row
                Row(
                  children: [
                    // Properties count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            visibleCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // University selector (browse mode only)
                    if (widget.mode == PropertyMapMode.browse)
                      GestureDetector(
                        onTap: _universityMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school_rounded,
                                color: primaryColor,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _selectedUniversity == 'Zote'
                                    ? context.tr('Vyote', en: 'All')
                                    : _selectedUniversity,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.expand_more,
                                color: primaryColor,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Directions overlay (shown when route is active)
          if (_selectedPropertyForDirections != null)
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Row(
                      children: [
                        Icon(
                          Icons.directions_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('Njia ya kwenda', en: 'Route to'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearRoute,
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Next turn instruction (prominent)
                    if (_nextTurnInstruction.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _nextTurnInstruction,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Distance and duration
                    Row(
                      children: [
                        Expanded(
                          child: _buildRouteInfoCard(
                            icon: Icons.straighten_rounded,
                            label: context.tr('Umbali', en: 'Distance'),
                            value: _routeDistance.isNotEmpty
                                ? _routeDistance
                                : context.tr(
                                    'Inahesabu...',
                                    en: 'Calculating...',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRouteInfoCard(
                            icon: Icons.access_time_rounded,
                            label: context.tr('Muda', en: 'Duration'),
                            value: _routeDuration.isNotEmpty
                                ? _routeDuration
                                : context.tr(
                                    'Inahesabu...',
                                    en: 'Calculating...',
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Turn-by-turn instructions list (collapsed)
                    if (_turnByTurnInstructions.isNotEmpty) ...[
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('Maelekezo yote:', en: 'All instructions:'),
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _turnByTurnInstructions.length,
                          itemBuilder: (context, index) {
                            final isCurrentStep = index == _currentStepIndex;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isCurrentStep
                                          ? primaryColor
                                          : primaryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isCurrentStep
                                              ? Colors.white
                                              : primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _turnByTurnInstructions[index],
                                      style: TextStyle(
                                        color: isCurrentStep
                                            ? primaryColor
                                            : textColor,
                                        fontSize: 13,
                                        fontWeight: isCurrentStep
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Floating current location button (bottom right)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'location',
                mini: true,
                onPressed: _isGettingLocation ? null : _determinePosition,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: _isGettingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.my_location_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
              ),
            ),
          ),
          // Floating compact bottom summary
          Positioned(
            bottom: 16,
            left: 16,
            right: 72,
            child: _buildCompactBottomSummary(context, visibleCount),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _universityMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.school_rounded, color: primaryColor),
      onSelected: _setUniversity,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'Zote',
          child: Text(context.tr('Vyote', en: 'All')),
        ),
        ..._universities.map(
          (uni) => PopupMenuItem(
            value: uni['name'] as String,
            child: Text(uni['name'] as String),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilterChip(String value) {
    final label = value == 'Zote'
        ? context.tr('Zote', en: 'All')
        : value.replaceAll('_', ' ');
    final selected = _selectedType == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedType = value);
        _refreshAnnotations();
      },
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRouteInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: subtextColor, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBottomSummary(BuildContext context, int visibleCount) {
    if (_clusters.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        _showPropertyListBottomSheet();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.list_rounded, color: primaryColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.tr(
                  'Nyumba $visibleCount zimepatikana',
                  en: '$visibleCount properties found',
                ),
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.expand_less, color: subtextColor, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPropertyListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      context.tr('Nyumba Zote', en: 'All Properties'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Property list
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clusters.length,
                  itemBuilder: (context, index) {
                    final cluster = _clusters[index];
                    final spot = cluster.spots.first;
                    return _buildPropertyListItem(spot, cluster.spots.length);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyListItem(RentalSpot spot, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: spot.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: spot.images.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: surfaceColor,
                      child: Icon(
                        Icons.home_rounded,
                        color: subtextColor,
                        size: 24,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: surfaceColor,
                      child: Icon(
                        Icons.broken_image,
                        color: subtextColor,
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: surfaceColor,
                    child: Icon(
                      Icons.home_rounded,
                      color: subtextColor,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Property info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.brandName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  spot.location,
                  style: TextStyle(color: subtextColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      spot.formattedPrice,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (count > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${count - 1}',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // View button
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: primaryColor, size: 16),
            onPressed: () {
              Navigator.pop(context);
              _navigateToPropertyDetail(spot);
            },
          ),
        ],
      ),
    );
  }

  void _navigateToPropertyDetail(RentalSpot spot) {
    // Navigate to property detail - placeholder for navigation logic
    // This would typically navigate to RentalDetailScreen or similar
  }

  /// SERK Navigation Start - Simple Mapbox Directions API flow
  Future<void> _getDirections(RentalSpot spot) async {
    // Get current position
    if (_currentPosition == null) {
      await _determinePosition();
      if (_currentPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('Tafadhali wezesha GPS', en: 'Please enable GPS'),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isGettingDirections = true;
      _selectedPropertyForDirections = spot;
    });

    try {
      // Mapbox Directions API
      final mapboxToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
      if (mapboxToken == null) throw Exception('Mapbox token not found');

      final mapboxApi = MapboxApi(accessToken: mapboxToken);

      final response = await mapboxApi.directions.request(
        profile: NavigationProfile.DRIVING,
        overview: NavigationOverview.FULL,
        geometries: NavigationGeometries.POLYLINE6,
        steps: true,
        coordinates: [
          [_currentPosition!.latitude, _currentPosition!.longitude],
          [spot.latitude, spot.longitude],
        ],
      );

      if (response.error != null ||
          response.routes == null ||
          response.routes!.isEmpty) {
        throw Exception('No route found');
      }

      final route = response.routes!.first;

      // Parse route data
      final distance = route.distance ?? 0;
      final duration = route.duration ?? 0;

      // Parse turn-by-turn steps
      final steps = <_RouteStep>[];
      if (route.legs != null) {
        for (final leg in route.legs!) {
          if (leg.steps != null) {
            for (final step in leg.steps!) {
              if (step.maneuver != null && step.maneuver!.modifier != null) {
                final instruction = _parseManeuver(step.maneuver!.modifier!);
                if (step.maneuver!.location != null &&
                    step.maneuver!.location!.length >= 2) {
                  steps.add(
                    _RouteStep(
                      lat: step.maneuver!.location![1],
                      lng: step.maneuver!.location![0],
                      instruction: instruction,
                      distance: step.distance ?? 0,
                      modifier: step.maneuver!.modifier,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      setState(() {
        _routeSteps = steps;
        _currentStepIndex = 0;
        _remainingDistance = distance;
        _etaTime = _calculateETA(duration);
        _currentInstruction = steps.isNotEmpty
            ? 'In ${_formatDistance(steps[0].distance)}: ${steps[0].instruction}'
            : '';
      });

      // Draw route on Mapbox map
      if (route.geometry != null) {
        await _drawRoute(route.geometry!);
      }

      // Start GPS tracking
      _startNavigationTracking();

      // Enable navigation mode
      setState(() {
        _isNavigating = true;
      });

      // Zoom to route
      await _fitRouteToCamera([
        mapbox.Position(
          _currentPosition!.longitude,
          _currentPosition!.latitude,
        ),
        mapbox.Position(spot.longitude, spot.latitude),
      ]);

      // 🔊 Play navigation start sound
      _playNavigationSound('navigation_start');

      // 🔊 Announce first instruction
      if (steps.isNotEmpty) {
        _speak(
          'Starting navigation. ${steps[0].instruction} in ${_formatDistance(steps[0].distance)}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Imeshindika kupata njia: $e',
                en: 'Failed to get directions: $e',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingDirections = false);
      }
    }
  }

  String _calculateETA(double seconds) {
    final now = DateTime.now();
    final arrival = now.add(Duration(seconds: seconds.round()));
    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _parseManeuver(NavigationManeuverModifier? modifier) {
    if (modifier == null) {
      return context.tr('Endelea moja kwa moja', en: 'Continue straight');
    }

    switch (modifier) {
      case NavigationManeuverModifier.LEFT:
        return context.tr('Geuka kushoto', en: 'Turn left');
      case NavigationManeuverModifier.RIGHT:
        return context.tr('Geuka kulia', en: 'Turn right');
      case NavigationManeuverModifier.SLIGHT_LEFT:
        return context.tr('Geuka kushoto kidogo', en: 'Turn slight left');
      case NavigationManeuverModifier.SLIGHT_RIGHT:
        return context.tr('Geuka kulia kidogo', en: 'Turn slight right');
      case NavigationManeuverModifier.SHARP_LEFT:
        return context.tr('Geuka kushoto vibaya', en: 'Turn sharp left');
      case NavigationManeuverModifier.SHARP_RIGHT:
        return context.tr('Geuka kulia vibaya', en: 'Turn sharp right');
      case NavigationManeuverModifier.UTURN:
        return context.tr('Rudi nyuma', en: 'U-turn');
      case NavigationManeuverModifier.STRAIGHT:
        return context.tr('Endelea moja kwa moja', en: 'Continue straight');
    }
  }

  /// SERK Navigation Tracking - Simple GPS stream
  void _startNavigationTracking() {
    _positionStreamSubscription?.cancel();

    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (position) {
            if (!_isNavigating) return;

            if (!_isGpsPositionValid(position)) return;

            _currentPosition = position;
            _updateNavigation(position);
          },
          onError: (error) {
            debugPrint('GPS Error: $error');
          },
        );
  }

  /// SERK Navigation Update - Simple turn-by-turn logic
  void _updateNavigation(geo.Position position) {
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) {
      _checkArrival(position);
      return;
    }

    final currentStep = _routeSteps[_currentStepIndex];
    final distanceToStep = _distanceKm(
      position.latitude,
      position.longitude,
      currentStep.lat,
      currentStep.lng,
    );

    // Update UI
    setState(() {
      _remainingDistance = distanceToStep * 1000;
      _currentInstruction =
          'In ${_formatDistance(_remainingDistance)}: ${currentStep.instruction}';
    });

    // Update camera to follow user
    _updateCameraForNavigation(position);

    // Simple turn announcement (200m, 100m, 50m)
    final distanceMeters = distanceToStep * 1000;
    if (_shouldAnnounceTurn(distanceMeters, _currentStepIndex)) {
      _speak(
        '${currentStep.instruction} in ${_formatDistance(distanceMeters)}',
      );
      _lastAnnouncedStepIndex = _currentStepIndex;
      _lastAnnouncedDistance = distanceMeters;
    }

    // Step completion (within 20m - simple threshold)
    if (distanceToStep < 0.02) {
      _currentStepIndex++;

      if (_currentStepIndex < _routeSteps.length) {
        final nextStep = _routeSteps[_currentStepIndex];
        setState(() {
          _currentInstruction =
              'In ${_formatDistance(nextStep.distance)}: ${nextStep.instruction}';
        });
        _speak(nextStep.instruction);
        _lastAnnouncedStepIndex = _currentStepIndex;
      } else {
        _checkArrival(position);
      }
    }

    // Simple off-route check (100m)
    if (distanceToStep > 0.1) {
      _reRoute(position);
    }
  }

  Future<void> _updateCameraForNavigation(geo.Position position) async {
    if (_mapboxMap == null) return;

    await _mapboxMap?.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(position.longitude, position.latitude),
        ),
        zoom: 16.0,
        bearing: position.heading,
        pitch: 45.0,
      ),
    );
  }

  bool _shouldAnnounceTurn(double distance, int stepIndex) {
    if (_lastAnnouncedStepIndex == stepIndex) {
      return (distance < _lastAnnouncedDistance - 100) || distance < 50;
    }

    // Simple announcement points: 200m, 100m, 50m
    return distance <= 200 || distance <= 100 || distance <= 50;
  }

  /// SERK Rerouting - Simple route recalculation
  Future<void> _reRoute(geo.Position position) async {
    if (_selectedPropertyForDirections == null) return;

    try {
      final mapboxToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
      if (mapboxToken == null) return;

      final mapboxApi = MapboxApi(accessToken: mapboxToken);

      final response = await mapboxApi.directions.request(
        profile: NavigationProfile.DRIVING,
        overview: NavigationOverview.FULL,
        geometries: NavigationGeometries.POLYLINE6,
        steps: true,
        coordinates: [
          [position.latitude, position.longitude],
          [
            _selectedPropertyForDirections!.latitude,
            _selectedPropertyForDirections!.longitude,
          ],
        ],
      );

      if (response.error != null ||
          response.routes == null ||
          response.routes!.isEmpty) {
        return;
      }

      final route = response.routes!.first;

      await _clearRoute();
      if (route.geometry != null) {
        await _drawRoute(route.geometry!);
      }

      // Parse steps
      final steps = <_RouteStep>[];
      if (route.legs != null) {
        for (final leg in route.legs!) {
          if (leg.steps != null) {
            for (final step in leg.steps!) {
              if (step.maneuver != null && step.maneuver!.modifier != null) {
                final instruction = _parseManeuver(step.maneuver!.modifier!);
                if (step.maneuver!.location != null &&
                    step.maneuver!.location!.length >= 2) {
                  steps.add(
                    _RouteStep(
                      lat: step.maneuver!.location![1],
                      lng: step.maneuver!.location![0],
                      instruction: instruction,
                      distance: step.distance ?? 0,
                      modifier: step.maneuver!.modifier,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      setState(() {
        _routeSteps = steps;
        _currentStepIndex = 0;
        _remainingDistance = route.distance ?? 0;
        _lastAnnouncedStepIndex = -1;
      });

      // Play rerouting sound and announce
      _playNavigationSound('rerouting');
      _speak('Recalculating route');
    } catch (e) {
      debugPrint('Reroute Error: $e');
    }
  }

  /// SERK Arrival Detection - Simple 30m threshold
  void _checkArrival(geo.Position position) {
    if (_selectedPropertyForDirections == null) return;

    final distanceToDestination = _distanceKm(
      position.latitude,
      position.longitude,
      _selectedPropertyForDirections!.latitude,
      _selectedPropertyForDirections!.longitude,
    );

    if (distanceToDestination < 0.03) {
      // 30m threshold
      // Play arrival sound
      _playNavigationSound('destination_reached');

      // Stop navigation and announce
      _stopNavigation();
      _speak('You have arrived at your destination');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Umefika!', en: 'You have arrived!')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// SERK Navigation Stop - Clean shutdown
  Future<void> _stopNavigation() async {
    await _flutterTts?.stop();
    _positionStreamSubscription?.cancel();
    await _clearRoute();

    setState(() {
      _isNavigating = false;
      _isGettingDirections = false;
      _selectedPropertyForDirections = null;
      _routeSteps = [];
      _currentStepIndex = 0;
      _currentInstruction = '';
      _remainingDistance = 0;
      _etaTime = '';
      _lastAnnouncedStepIndex = -1;
      _lastAnnouncementTime = null;
    });
  }

  Future<void> _drawRoute(String encodedPolyline) async {
    final manager = _polylineManager;
    if (manager == null) return;

    // Clear existing route
    if (_routePolyline != null) {
      await manager.delete(_routePolyline!);
      _routePolyline = null;
    }

    // Decode polyline
    final decoded = PolylineTools.decodePolyline(encodedPolyline);
    final points = decoded.map((latLng) {
      return mapbox.Point(
        coordinates: mapbox.Position(latLng.longitude, latLng.latitude),
      );
    }).toList();

    if (points.isEmpty) return;

    // Create LineString
    final lineString = mapbox.LineString.fromPoints(points: points);

    // Create multi-layer route for better visualization (like Google Maps)
    // 1. Outer glow/shadow layer for visibility
    await manager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: const Color(0xFF4285F4).toARGB32(),
        lineWidth: 12.0,
        lineOpacity: 0.3,
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );

    // 2. Main route line (thick blue)
    final mainRoute = await manager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: const Color(0xFF4285F4).toARGB32(),
        lineWidth: 8.0,
        lineOpacity: 1.0,
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );

    // 3. Inner bright line (lighter blue for road center)
    await manager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: const Color(0xFF64B5F6).toARGB32(),
        lineWidth: 4.0,
        lineOpacity: 1.0,
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );

    setState(() {
      _routePolyline = mainRoute;
    });
  }

  Future<void> _fitRouteToCamera(List<mapbox.Position> positions) async {
    if (positions.isEmpty || _mapboxMap == null) return;

    // Calculate bounds
    final lngs = positions.map((p) => p.lng).toList();
    final lats = positions.map((p) => p.lat).toList();

    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);

    // Calculate center
    final centerLng = (minLng + maxLng) / 2;
    final centerLat = (minLat + maxLat) / 2;

    await _mapboxMap?.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(centerLng, centerLat),
        ),
        zoom: 14,
      ),
    );
  }

  Future<void> _clearRoute() async {
    final manager = _polylineManager;
    if (manager == null) return;

    if (_routePolyline != null) {
      await manager.delete(_routePolyline!);
      _routePolyline = null;
    }

    _positionStreamSubscription?.cancel();

    // Remove current location marker
    if (_currentLocationMarker != null) {
      final annotationManager = _annotationManager;
      if (annotationManager != null) {
        await annotationManager.delete(_currentLocationMarker!);
      }
      _currentLocationMarker = null;
    }

    if (mounted) {
      setState(() {
        _selectedPropertyForDirections = null;
        _routeDistance = '';
        _routeDuration = '';
        _turnByTurnInstructions = [];
        _routeSteps = [];
        _currentStepIndex = 0;
        _nextTurnInstruction = '';
      });
    }
  }
}

class _ClusterBucket {
  final double lat;
  final double lng;
  final List<RentalSpot> spots;

  const _ClusterBucket({
    required this.lat,
    required this.lng,
    required this.spots,
  });

  String get cacheKey =>
      '${lat.toStringAsFixed(4)}:${lng.toStringAsFixed(4)}:${spots.length}:${spots.first.type}';
}

class _RouteStep {
  final double lat;
  final double lng;
  final String instruction;
  final double distance;
  final NavigationManeuverModifier? modifier;

  const _RouteStep({
    required this.lat,
    required this.lng,
    required this.instruction,
    required this.distance,
    this.modifier,
  });
}
