import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  const MapboxPropertyMapPage.browse({
    super.key,
    this.selectedUniversity,
  }) : mode = PropertyMapMode.browse;

  const MapboxPropertyMapPage.landlord({
    super.key,
  }) : mode = PropertyMapMode.landlord,
       selectedUniversity = null;

  @override
  State<MapboxPropertyMapPage> createState() => _MapboxPropertyMapPageState();
}

class _MapboxPropertyMapPageState extends State<MapboxPropertyMapPage> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _annotationManager;
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

  @override
  void initState() {
    super.initState();
    if (widget.selectedUniversity != null) {
      _selectedUniversity = widget.selectedUniversity!;
    }
    _loadData();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final housesJson = widget.mode == PropertyMapMode.landlord
          ? await ApiService.getMyHouses()
          : await ApiService.getAllHouses();

      final loaded = housesJson.map((json) {
        final house = HouseData.fromJson(json as Map<String, dynamic>);
        return RentalSpot.fromHouseData(house);
      }).where((spot) => spot.hasValidLocation()).toList();

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
        final map = _mapboxMap;
        if (mounted) {
          await map?.setCamera(
            mapbox.CameraOptions(
              center: mapbox.Point(
                coordinates: mapbox.Position(position.longitude, position.latitude),
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
        }
      }
    } catch (_) {}
  }

  Future<void> _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
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
      final matchesSearch = query.isEmpty ||
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
      final matchesPrice = spot.rentPrice >= _minPrice && spot.rentPrice <= _maxPrice;
      final matchesUniversity = _selectedUniversity == 'Zote' ||
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
    final a = sin(dLat / 2) * sin(dLat / 2) +
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
      final lat = items.fold<double>(0, (sum, spot) => sum + spot.latitude) / items.length;
      final lng = items.fold<double>(0, (sum, spot) => sum + spot.longitude) / items.length;
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
    );
    _iconCache[key] = image;
    return image;
  }

  Future<Uint8List> _buildClusterBitmap(int count, double price) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 160.0;
    final isCluster = count > 1;
    final fill = isCluster ? const Color(0xFF0F8B61) : primaryColor;

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 10), 30, shadow);

    final circlePaint = Paint()..color = fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), isCluster ? 34 : 30, circlePaint);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      isCluster ? 34 : 30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final label = isCluster
        ? '$count'
        : _formatPrice(price);

    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: isCluster ? 26 : 18,
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2 - 2),
    );

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

  Future<void> _openDirections(RentalSpot spot) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleTap(mapbox.MapContentGestureContext context) async {
    final tappedLat = context.point.coordinates.lat;
    final tappedLng = context.point.coordinates.lng;
    final clusters = _buildClusters(_filterSpots(_spots), _currentZoom);
    if (clusters.isEmpty) return;

    final nearest = clusters
        .map((cluster) => (cluster: cluster, distance: _distanceKm(
              tappedLat.toDouble(),
              tappedLng.toDouble(),
              cluster.lat,
              cluster.lng,
            )))
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final closest = nearest.first;
    if (closest.distance > 0.8) return;

    if (closest.cluster.spots.length > 1) {
      await _mapboxMap?.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(closest.cluster.lng, closest.cluster.lat),
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
                          spot.brandName.isNotEmpty ? spot.brandName : spot.ownerName,
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
                      onPressed: () => _openDirections(spot),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Directions'),
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

  @override
  Widget build(BuildContext context) {
    final visibleCount = _visibleSpots().length;
    final initialCenter = _spots.isNotEmpty
        ? mapbox.Position(_spots.first.longitude, _spots.first.latitude)
        : mapbox.Position(_defaultPosition.longitude, _defaultPosition.latitude);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.mode == PropertyMapMode.landlord
              ? context.tr('Ramani ya Nyumba Zangu', en: 'My Houses Map')
              : context.tr('Ramani ya Nyumba', en: 'Property Map'),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _determinePosition,
            icon: const Icon(Icons.my_location_rounded),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          mapbox.MapWidget(
            key: const ValueKey('mapbox-property-map'),
            cameraOptions: mapbox.CameraOptions(
              center: mapbox.Point(coordinates: initialCenter),
              zoom: 12,
            ),
            styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChangeListener,
            onTapListener: _handleTap,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Icon(Icons.search_rounded, color: subtextColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _refreshAnnotations();
                      },
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: context.tr(
                          'Tafuta nyumba, eneo, bei...',
                          en: 'Search houses, area, price...',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: primaryColor),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _refreshAnnotations();
                      },
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 82,
            left: 16,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('Zote'),
                ...['self_container', 'shared', 'bedsitter', 'studio', 'flat'].map(
                  (type) => _filterChip(type),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 144,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildStatPill(
                  context.tr('Nyumba', en: 'Properties'),
                  visibleCount.toString(),
                ),
                const SizedBox(width: 12),
                if (widget.mode == PropertyMapMode.browse)
                  _buildStatPill(
                    context.tr('Vyuo', en: 'Universities'),
                    _selectedUniversity == 'Zote' ? 'All' : _selectedUniversity,
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 96,
            right: 16,
            child: FloatingActionButton(
              onPressed: _isGettingLocation ? null : _determinePosition,
              backgroundColor: surfaceColor,
              foregroundColor: primaryColor,
              child: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildBottomSummary(context, visibleCount),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          if (widget.mode == PropertyMapMode.browse)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 210,
              child: _universityMenu(),
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
          child: Text(
            context.tr('Vyote', en: 'All'),
          ),
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

  Widget _filterChip(String value) {
    final label = value == 'Zote'
        ? context.tr('Zote', en: 'All')
        : value.replaceAll('_', ' ');
    final selected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedType = value);
        _refreshAnnotations();
      },
    );
  }

  Widget _buildStatPill(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: subtextColor, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, int visibleCount) {
    return GestureDetector(
      onTap: () {
        if (_clusters.isEmpty) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clusters.length,
              itemBuilder: (context, index) {
                final spot = _clusters[index].spots.first;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _showPropertyDetails(spot);
                  },
                  leading: spot.images.isNotEmpty
                      ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(spot.images.first))
                      : CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Icon(Icons.home_rounded, color: primaryColor),
                        ),
                  title: Text(spot.brandName.isNotEmpty ? spot.brandName : spot.ownerName),
                  subtitle: Text(spot.getShortAddress()),
                  trailing: Text(spot.formattedPrice),
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr(
                  'Tap property markers to view details and directions',
                  en: 'Tap property markers to view details and directions',
                ),
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$visibleCount',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
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
      '${lat.toStringAsFixed(4)}:${lng.toStringAsFixed(4)}:${spots.length}';
}
