import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:polyline_tools/polyline_tools.dart';
import 'package:flutter/foundation.dart';

/// Main route result containing multiple route options
class RouteResult {
  final List<RouteOption> options;
  final RouteOption selectedOption;

  RouteResult({required this.options, required this.selectedOption});

  RouteResult copyWith({
    List<RouteOption>? options,
    RouteOption? selectedOption,
  }) {
    return RouteResult(
      options: options ?? this.options,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}

/// Single route option (e.g., fastest, shortest, alternative)
class RouteOption {
  final String id;
  final String name;
  final double distanceKm;
  final double durationMinutes;
  final String? polyline; // Encoded polyline for map display
  final List<NavigationStep> steps;
  final bool isRecommended;

  RouteOption({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.durationMinutes,
    this.polyline,
    required this.steps,
    required this.isRecommended,
  });

  List<LatLng> get decodedPolyline {
    if (polyline == null || polyline!.isEmpty) return [];

    try {
      final points = PolylineTools.decodePolyline(polyline!);

      return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      debugPrint('Polyline decode error: $e');
      return [];
    }
  }

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes.toStringAsFixed(0)} min';
    }
    final hours = (durationMinutes / 60).floor();
    final mins = (durationMinutes % 60).round();
    return '${hours}h ${mins}min';
  }
}

/// Individual navigation step (turn, continue, arrive, etc.)
class NavigationStep {
  final double latitude;
  final double longitude;
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final ManeuverType maneuverType;
  final String? streetName;

  NavigationStep({
    required this.latitude,
    required this.longitude,
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    this.streetName,
  });

  LatLng get coordinate => LatLng(latitude, longitude);

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  NavigationStep copyWith({
    double? latitude,
    double? longitude,
    String? instruction,
    double? distanceMeters,
    double? durationSeconds,
    ManeuverType? maneuverType,
    String? streetName,
  }) {
    return NavigationStep(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instruction: instruction ?? this.instruction,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      maneuverType: maneuverType ?? this.maneuverType,
      streetName: streetName ?? this.streetName,
    );
  }
}

/// Type of navigation maneuver
enum ManeuverType {
  turn,
  continueStraight,
  arrive,
  depart,
  merge,
  ramp,
  roundabout,
  fork,
  uturn,
}

/// Direction for turn maneuvers
enum TurnDirection {
  left,
  right,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  straight,
  uturn,
}

/// Traffic level indicator
enum TrafficLevel { low, moderate, heavy, severe }
