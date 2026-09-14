import 'package:geolocator/geolocator.dart' as geo;
import 'package:serik/models/route_model.dart';

/// Navigation state machine for production-grade state management
enum NavigationState {
  initializing,
  loadingRoute,
  routeReady,
  navigating,
  rerouting,
  arrived,
  cancelled,
  error,
}

/// Navigation error types
enum NavigationErrorType {
  noLocationPermission,
  locationServiceDisabled,
  locationUnavailable,
  routingApiFailed,
  networkError,
  invalidDestination,
  unknown,
}

/// Complete navigation state model
class NavigationStateModel {
  final NavigationState state;
  final NavigationErrorType? errorType;
  final String? errorMessage;
  
  // Route data
  final RouteResult? routeResult;
  final RouteOption? selectedRoute;
  final int currentStepIndex;
  
  // Position data
  final geo.Position? currentPosition;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final double currentSpeedKmh;
  final double journeyProgress;
  
  // Timing
  final DateTime? estimatedArrivalTime;
  final DateTime? navigationStartTime;
  
  // Settings
  final bool isVoiceEnabled;
  final bool isMuted;
  final bool isCameraFollowing;
  
  NavigationStateModel({
    this.state = NavigationState.initializing,
    this.errorType,
    this.errorMessage,
    this.routeResult,
    this.selectedRoute,
    this.currentStepIndex = 0,
    this.currentPosition,
    this.remainingDistanceMeters = 0,
    this.remainingDurationSeconds = 0,
    this.currentSpeedKmh = 0,
    this.journeyProgress = 0,
    this.estimatedArrivalTime,
    this.navigationStartTime,
    this.isVoiceEnabled = true,
    this.isMuted = false,
    this.isCameraFollowing = true,
  });

  NavigationStateModel copyWith({
    NavigationState? state,
    NavigationErrorType? errorType,
    String? errorMessage,
    RouteResult? routeResult,
    RouteOption? selectedRoute,
    int? currentStepIndex,
    geo.Position? currentPosition,
    double? remainingDistanceMeters,
    double? remainingDurationSeconds,
    double? currentSpeedKmh,
    double? journeyProgress,
    DateTime? estimatedArrivalTime,
    DateTime? navigationStartTime,
    bool? isVoiceEnabled,
    bool? isMuted,
    bool? isCameraFollowing,
  }) {
    return NavigationStateModel(
      state: state ?? this.state,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
      routeResult: routeResult ?? this.routeResult,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentPosition: currentPosition ?? this.currentPosition,
      remainingDistanceMeters: remainingDistanceMeters ?? this.remainingDistanceMeters,
      remainingDurationSeconds: remainingDurationSeconds ?? this.remainingDurationSeconds,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      journeyProgress: journeyProgress ?? this.journeyProgress,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      navigationStartTime: navigationStartTime ?? this.navigationStartTime,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      isMuted: isMuted ?? this.isMuted,
      isCameraFollowing: isCameraFollowing ?? this.isCameraFollowing,
    );
  }

  NavigationStateModel withError(NavigationErrorType type, String message) {
    return copyWith(
      state: NavigationState.error,
      errorType: type,
      errorMessage: message,
    );
  }

  NavigationStateModel withRouteReady(RouteResult result) {
    return copyWith(
      state: NavigationState.routeReady,
      routeResult: result,
      selectedRoute: result.selectedOption,
      currentStepIndex: 0,
      remainingDistanceMeters: result.selectedOption.distanceKm * 1000,
      remainingDurationSeconds: result.selectedOption.durationMinutes * 60,
    );
  }

  NavigationStateModel withNavigating() {
    return copyWith(
      state: NavigationState.navigating,
      navigationStartTime: DateTime.now(),
    );
  }

  NavigationStateModel withRerouting() {
    return copyWith(
      state: NavigationState.rerouting,
    );
  }

  NavigationStateModel withArrived() {
    return copyWith(
      state: NavigationState.arrived,
      remainingDistanceMeters: 0,
      remainingDurationSeconds: 0,
      journeyProgress: 1.0,
    );
  }

  NavigationStateModel withCancelled() {
    return copyWith(
      state: NavigationState.cancelled,
    );
  }

  // Convenience getters
  bool get isLoading => state == NavigationState.initializing || state == NavigationState.loadingRoute;
  bool get isNavigating => state == NavigationState.navigating;
  bool get isRerouting => state == NavigationState.rerouting;
  bool get hasArrived => state == NavigationState.arrived;
  bool get hasError => state == NavigationState.error;
  bool get canNavigate => state == NavigationState.routeReady;

  NavigationStep? get currentStep {
    if (selectedRoute == null || currentStepIndex >= selectedRoute!.steps.length) {
      return null;
    }
    return selectedRoute!.steps[currentStepIndex];
  }

  NavigationStep? get nextStep {
    if (selectedRoute == null || currentStepIndex + 1 >= selectedRoute!.steps.length) {
      return null;
    }
    return selectedRoute!.steps[currentStepIndex + 1];
  }

  String get formattedRemainingDistance {
    if (remainingDistanceMeters < 1000) {
      return '${remainingDistanceMeters.round()} m';
    }
    return '${(remainingDistanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedRemainingDuration {
    if (remainingDurationSeconds < 60) {
      return '${remainingDurationSeconds.round()} s';
    }
    final minutes = (remainingDurationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = (minutes / 60).floor();
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  String get formattedCurrentSpeed {
    return '${currentSpeedKmh.toStringAsFixed(0)} km/h';
  }

  String get formattedETA {
    if (estimatedArrivalTime == null) return '--:--';
    final hour = estimatedArrivalTime!.hour.toString().padLeft(2, '0');
    final minute = estimatedArrivalTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
