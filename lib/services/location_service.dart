import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;

/// Service for handling location tracking and permissions
/// Wraps Geolocator with production-grade error handling
class LocationService {
  LocationService._();

  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  StreamSubscription<geo.Position>? _positionStream;
  geo.Position? _currentPosition;
  geo.Position? _lastPosition;
  DateTime? _lastPositionTime;
  final _positionController = StreamController<geo.Position>.broadcast();

  Stream<geo.Position> get positionStream => _positionController.stream;
  geo.Position? get currentPosition => _currentPosition;

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    final permission = await geo.Geolocator.checkPermission();
    return _parsePermissionStatus(permission);
  }

  /// Request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await geo.Geolocator.requestPermission();
    return _parsePermissionStatus(permission);
  }

  /// Get current position with error handling
  Future<geo.Position?> getCurrentPosition({
    geo.LocationAccuracy accuracy = geo.LocationAccuracy.high,
  }) async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location service is disabled');
      }

      // Check permission
      final permission = await checkPermissionStatus();
      if (permission == LocationPermissionStatus.denied) {
        final requested = await requestPermission();
        if (requested == LocationPermissionStatus.denied) {
          throw LocationException('Location permission denied');
        }
        if (requested == LocationPermissionStatus.deniedForever) {
          throw LocationException('Location permission permanently denied');
        }
      }

      // Get position
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: accuracy,
          timeLimit: const Duration(seconds: 30),
        ),
      );

      _currentPosition = position;
      _positionController.add(position);
      return position;
    } catch (e) {
      throw LocationException('Failed to get current position: $e');
    }
  }

  /// Start continuous position tracking
  Future<void> startPositionTracking({
    geo.LocationAccuracy accuracy = geo.LocationAccuracy.high,
    int distanceFilter = 5, // meters
  }) async {
    // Stop existing stream
    await stopPositionTracking();

    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location service is disabled');
      }

      final permission = await checkPermissionStatus();
      if (permission == LocationPermissionStatus.denied ||
          permission == LocationPermissionStatus.deniedForever) {
        throw LocationException('Location permission not granted');
      }

      _positionStream = geo.Geolocator.getPositionStream(
        locationSettings: geo.LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      ).listen(
        (position) {
          // Filter out noisy GPS data
          if (_isValidPosition(position)) {
            _currentPosition = position;
            _positionController.add(position);
          }
        },
        onError: (error) {
          _positionController.addError(LocationException('GPS error: $error'));
        },
      );
    } catch (e) {
      throw LocationException('Failed to start position tracking: $e');
    }
  }

  /// Stop position tracking
  Future<void> stopPositionTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  /// Calculate distance between two points in meters
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return geo.Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate bearing between two points in degrees
  double bearingBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return geo.Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Open app settings for location permission
  Future<bool> openAppSettings() async {
    return await geo.Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await geo.Geolocator.openLocationSettings();
  }

  /// Validate GPS position (filter noisy data)
  bool _isValidPosition(geo.Position position) {
    // Check if coordinates are valid
    if (position.latitude.abs() > 90 || position.longitude.abs() > 180) {
      return false;
    }

    // Check if accuracy is reasonable
    if (position.accuracy > 100) { // More than 100m accuracy is poor
      return false;
    }

    // Check if speed is realistic (less than 300 km/h)
    if (position.speed > 83.3) { // 300 km/h in m/s
      return false;
    }
    
    // Check for impossible jumps (more than 3km in 1 second)
    if (_lastPosition != null && _lastPositionTime != null) {
      final timeDiff = position.timestamp.difference(_lastPositionTime!).inSeconds;
      if (timeDiff > 0 && timeDiff < 2) {
        final distance = distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance > 3000) { // More than 3km in < 2 seconds is impossible
          return false;
        }
      }
    }
    
    // Update last position
    _lastPosition = position;
    _lastPositionTime = position.timestamp;

    return true;
  }

  /// Parse Geolocator permission to our enum
  LocationPermissionStatus _parsePermissionStatus(geo.LocationPermission permission) {
    switch (permission) {
      case geo.LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case geo.LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case geo.LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case geo.LocationPermission.always:
        return LocationPermissionStatus.always;
      default:
        return LocationPermissionStatus.unknown;
    }
  }

  void dispose() {
    stopPositionTracking();
    _positionController.close();
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  whileInUse,
  always,
  unknown,
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
