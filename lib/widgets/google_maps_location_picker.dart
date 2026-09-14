import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Maps location picker widget with GPS validation and reverse geocoding
/// Enhanced for production use with location verification
class GoogleMapsLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  final String? selectedRegion;
  final String? selectedDistrict;
  final String? selectedWard;

  const GoogleMapsLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
    this.selectedRegion,
    this.selectedDistrict,
    this.selectedWard,
  });

  @override
  State<GoogleMapsLocationPicker> createState() => _GoogleMapsLocationPickerState();
}

class _GoogleMapsLocationPickerState extends State<GoogleMapsLocationPicker> {
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng _selectedLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isReverseGeocoding = false;
  String _reverseGeocodedAddress = '';
  String _accuracyWarning = '';
  String _locationMismatchWarning = '';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(-6.7924, 39.2083);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        
        // Check GPS accuracy
        _validateGPSAccuracy(position);
        
        _updateMarker();
        _moveCameraToLocation();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _validateGPSAccuracy(Position position) {
    // GPS accuracy validation
    if (position.accuracy > 100) {
      setState(() {
        _accuracyWarning = '⚠️ GPS accuracy is low (${position.accuracy.toStringAsFixed(0)}m). Location may be inaccurate.';
      });
    } else if (position.accuracy > 50) {
      setState(() {
        _accuracyWarning = '⚠️ GPS accuracy is moderate (${position.accuracy.toStringAsFixed(0)}m). Verify location manually.';
      });
    } else {
      setState(() {
        _accuracyWarning = '';
      });
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          onDragEnd: (LatLng newLocation) {
            setState(() => _selectedLocation = newLocation);
            _performReverseGeocoding(newLocation);
          },
        ),
      };
    });
  }

  Future<void> _moveCameraToLocation() async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 15),
    );
  }

  Future<void> _performReverseGeocoding(LatLng location) async {
    setState(() {
      _isReverseGeocoding = true;
      _reverseGeocodedAddress = '';
      _locationMismatchWarning = '';
    });

    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('Google Maps API key not configured');
        setState(() => _isReverseGeocoding = false);
        return;
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final firstResult = results[0] as Map<String, dynamic>;
            final addressComponents = firstResult['address_components'] as List;
            
            String locality = '';
            String administrativeArea = '';
            
            for (final component in addressComponents) {
              final types = component['types'] as List;
              if (types.contains('locality')) {
                locality = component['long_name'] as String;
              }
              if (types.contains('administrative_area_level_1')) {
                administrativeArea = component['long_name'] as String;
              }
            }
            
            final formattedAddress = firstResult['formatted_address'] as String;
            
            setState(() {
              _reverseGeocodedAddress = formattedAddress;
            });
            
            // Check for location mismatch with administrative selections
            _checkLocationMismatch(locality, administrativeArea);
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    } finally {
      setState(() => _isReverseGeocoding = false);
    }
  }

  void _checkLocationMismatch(String locality, String administrativeArea) {
    // Check if reverse geocoded location matches administrative selections
    final warnings = <String>[];
    
    if (widget.selectedRegion != null && widget.selectedRegion!.isNotEmpty) {
      if (!administrativeArea.toLowerCase().contains(widget.selectedRegion!.toLowerCase()) &&
          !locality.toLowerCase().contains(widget.selectedRegion!.toLowerCase())) {
        warnings.add('Region mismatch: Geocoded location ($administrativeArea) does not match selected region (${widget.selectedRegion}).');
      }
    }
    
    if (widget.selectedDistrict != null && widget.selectedDistrict!.isNotEmpty) {
      if (!administrativeArea.toLowerCase().contains(widget.selectedDistrict!.toLowerCase()) &&
          !locality.toLowerCase().contains(widget.selectedDistrict!.toLowerCase())) {
        warnings.add('District mismatch: Geocoded location does not match selected district (${widget.selectedDistrict}).');
      }
    }
    
    if (widget.selectedWard != null && widget.selectedWard!.isNotEmpty) {
      if (!locality.toLowerCase().contains(widget.selectedWard!.toLowerCase())) {
        warnings.add('Ward mismatch: Geocoded location does not match selected ward (${widget.selectedWard}).');
      }
    }
    
    if (warnings.isNotEmpty) {
      setState(() {
        _locationMismatchWarning = warnings.join('\n');
      });
    } else {
      setState(() {
        _locationMismatchWarning = '';
      });
    }
  }

  bool _isValidCoordinate(LatLng location) {
    // Validate coordinate ranges
    if (location.latitude.abs() > 90 || location.longitude.abs() > 180) {
      return false;
    }
    return true;
  }

  void _confirmLocation() {
    if (!_isValidCoordinate(_selectedLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coordinates selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    widget.onLocationSelected(_selectedLocation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Get current location',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (controller) => _controller.complete(controller),
            onTap: (LatLng location) {
              setState(() => _selectedLocation = location);
              _updateMarker();
              _performReverseGeocoding(location);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          // GPS accuracy warning
          if (_accuracyWarning.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _accuracyWarning,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Location mismatch warning
          if (_locationMismatchWarning.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Location Mismatch Warning',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _locationMismatchWarning,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          
          // Reverse geocoded address
          if (_reverseGeocodedAddress.isNotEmpty || _isReverseGeocoding)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isReverseGeocoding
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Verifying location...'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📍 Detected Location:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _reverseGeocodedAddress,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
          
          // Current coordinates display
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Coordinates:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  if (_currentPosition != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Your current distance: ${_calculateDistance(_currentPosition!, _selectedLocation).toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Confirm button
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location'),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(Position position, LatLng location) {
    const double earthRadius = 6371000; // meters
    final lat1Rad = position.latitude * math.pi / 180;
    final lat2Rad = location.latitude * math.pi / 180;
    final deltaLat = lat2Rad - lat1Rad;
    final deltaLng = (location.longitude - position.longitude) * math.pi / 180;
    
    final a = (deltaLat / 2).abs() * (deltaLat / 2).abs() +
        lat1Rad.abs() * lat2Rad.abs() * (deltaLng / 2).abs() * (deltaLng / 2).abs();
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
}
