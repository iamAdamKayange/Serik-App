import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:serik/models/route_model.dart';

// Re-export types for convenience
export 'package:serik/models/route_model.dart';

/// Service for handling routing operations using Google Directions API
/// This provides routing for navigation
class GoogleMapsRoutingService {
  GoogleMapsRoutingService._();

  static GoogleMapsRoutingService? _instance;
  static GoogleMapsRoutingService get instance => _instance ??= GoogleMapsRoutingService._();

  String? _apiKey;

  GoogleMapsRoutingService() {
    // Try to load from environment variable first
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    
    // If not found, use the same key as configured in AndroidManifest.xml
    // This is a fallback for development/production where the API key is already configured
    if (_apiKey == null || _apiKey!.isEmpty) {
      _apiKey = 'AIzaSyCcyVSvRgnLL09Po6Y7IfyPoJq5vAUCEOU';
    }
  }

  /// Check if routing service is available
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get route from origin to destination
  Future<RouteResult> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'driving',
    bool includeAlternatives = true,
  }) async {
    if (!isAvailable) {
      throw RoutingException('Google Maps API key not configured');
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destinationLat,$destinationLng'
        '&mode=$travelMode'
        '&alternatives=$includeAlternatives'
        '&key=$_apiKey'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw RoutingException('Google Maps API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] != 'OK') {
        throw RoutingException('Google Maps error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
      }

      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        throw RoutingException('No routes found to this destination');
      }

      return _parseRouteResponse(data);
    } on TimeoutException {
      throw RoutingException('Routing request timed out. Please check your connection.');
    } catch (e) {
      throw RoutingException('Failed to get route: $e');
    }
  }

  /// Get multiple route options (fastest, shortest, etc.)
  Future<List<RouteOption>> getRouteOptions({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final result = await getRoute(
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      includeAlternatives: true,
    );
    return result.options;
  }

  /// Re-route from current position to destination
  Future<RouteResult> reRoute({
    required double currentLat,
    required double currentLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    return getRoute(
      originLat: currentLat,
      originLng: currentLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      includeAlternatives: false, // Fast re-route
    );
  }

  RouteResult _parseRouteResponse(Map<String, dynamic> data) {
    final routes = data['routes'] as List;
    final options = <RouteOption>[];

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i] as Map<String, dynamic>;
      final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>?;
      final points = overviewPolyline?['points'] as String?;

      final legs = route['legs'] as List?;
      final totalDistance = (route['distance'] as num?)?.toDouble() ?? 0;
      final totalDuration = (route['duration'] as num?)?.toDouble() ?? 0;

      final steps = _extractSteps(legs);

      options.add(RouteOption(
        id: 'route_$i',
        name: i == 0 ? 'Recommended route' : 'Alternative ${i + 1}',
        distanceKm: totalDistance / 1000,
        durationMinutes: totalDuration / 60,
        polyline: points,
        steps: steps,
        isRecommended: i == 0,
      ));
    }

    return RouteResult(
      options: options,
      selectedOption: options.first,
    );
  }

  List<NavigationStep> _extractSteps(List? legs) {
    final steps = <NavigationStep>[];

    if (legs == null) return steps;

    for (final leg in legs) {
      final legSteps = leg['steps'] as List?;
      if (legSteps == null) continue;

      for (final step in legSteps) {
        final stepMap = step as Map<String, dynamic>;
        final endLocation = stepMap['end_location'] as Map<String, dynamic>;
        final instruction = stepMap['html_instructions'] as String?;
        final distance = (stepMap['distance'] as num?)?.toDouble() ?? 0;
        final duration = (stepMap['duration'] as num?)?.toDouble() ?? 0;

        steps.add(NavigationStep(
          latitude: (endLocation['lat'] as num).toDouble(),
          longitude: (endLocation['lng'] as num).toDouble(),
          instruction: _stripHtmlTags(instruction ?? 'Continue'),
          distanceMeters: distance,
          durationSeconds: duration,
          maneuverType: _parseManeuverType(stepMap['maneuver'] as String?),
          streetName: (stepMap['maneuver'] as Map?)?['instruction']?.toString(),
        ));
      }
    }

    return steps;
  }

  String _stripHtmlTags(String html) {
    // Simple HTML tag removal for instructions
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  ManeuverType _parseManeuverType(String? maneuver) {
    if (maneuver == null) return ManeuverType.continueStraight;

    final lower = maneuver.toLowerCase();
    if (lower.contains('turn')) return ManeuverType.turn;
    if (lower.contains('uturn')) return ManeuverType.uturn;
    if (lower.contains('arrive')) return ManeuverType.arrive;
    if (lower.contains('depart')) return ManeuverType.depart;
    if (lower.contains('merge')) return ManeuverType.merge;
    if (lower.contains('ramp')) return ManeuverType.ramp;
    if (lower.contains('roundabout')) return ManeuverType.roundabout;
    if (lower.contains('fork')) return ManeuverType.fork;

    return ManeuverType.continueStraight;
  }
}

class RoutingException implements Exception {
  final String message;
  RoutingException(this.message);

  @override
  String toString() => 'RoutingException: $message';
}
