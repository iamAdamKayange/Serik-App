import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapboxLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final ValueChanged<LatLng?> onChanged;
  final double height;
  final bool enableCurrentLocation;

  const MapboxLocationPicker({
    super.key,
    required this.onChanged,
    this.initialLocation,
    this.height = 250,
    this.enableCurrentLocation = true,
  });

  @override
  State<MapboxLocationPicker> createState() => _MapboxLocationPickerState();
}

class _MapboxLocationPickerState extends State<MapboxLocationPicker> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _annotationManager;
  LatLng? _selectedLocation;
  bool _isGettingLocation = false;
  final Completer<void> _mapReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void didUpdateWidget(covariant MapboxLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation &&
        widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _refreshAnnotation();
    }
  }

  Future<void> _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    await mapboxMap.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
    if (!_mapReady.isCompleted) {
      _mapReady.complete();
    }
    await _refreshAnnotation();
    if (_selectedLocation != null) {
      await _moveCamera(_selectedLocation!, zoom: 16.5);
    }
  }

  Future<void> _moveCamera(LatLng location, {double zoom = 15.0}) async {
    final map = _mapboxMap;
    if (map == null) return;
    await map.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(location.longitude, location.latitude)),
        zoom: zoom,
      ),
    );
  }

  Future<void> _refreshAnnotation() async {
    final manager = _annotationManager;
    final location = _selectedLocation;
    if (manager == null) return;
    await manager.deleteAll();
    if (location == null) return;

    final image = await _buildPinBitmap(
      const Color(0xFFE11D48),
      const Color(0xFFFFFFFF),
    );
    await manager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(location.longitude, location.latitude),
        ),
        image: image,
        iconSize: 1.0,
      ),
    );
  }

  Future<void> _pickCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);
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
        final location = LatLng(position.latitude, position.longitude);
        _selectLocation(location);
        await _moveCamera(location, zoom: 16.5);
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _selectLocation(LatLng location) {
    setState(() => _selectedLocation = location);
    widget.onChanged(location);
    _refreshAnnotation();
  }

  Future<Uint8List> _buildPinBitmap(Color fill, Color border) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 120.0;

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 8), 26, shadow);

    final path = Path()
      ..moveTo(size / 2, 16)
      ..cubicTo(70, 16, 90, 38, 90, 60)
      ..cubicTo(90, 88, 60, 106, 60, 106)
      ..cubicTo(60, 106, 30, 88, 30, 60)
      ..cubicTo(30, 38, 50, 16, size / 2, 16)
      ..close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = border,
    );
    canvas.drawCircle(
      const Offset(size / 2, 55),
      14,
      Paint()..color = border,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialLocation ??
        const LatLng(-6.7924, 39.2083);
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: mapbox.MapWidget(
              key: const ValueKey('mapbox-location-picker'),
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(initial.longitude, initial.latitude),
                ),
                zoom: 15.0,
              ),
              styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
              textureView: true,
              onMapCreated: _onMapCreated,
              onTapListener: (context) {
                _selectLocation(
                  LatLng(
                    context.point.coordinates.lat.toDouble(),
                    context.point.coordinates.lng.toDouble(),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Tap the map to choose location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (widget.enableCurrentLocation) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isGettingLocation ? null : _pickCurrentLocation,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _isGettingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Center(
            child: Icon(
              Icons.place_rounded,
              size: 38,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
