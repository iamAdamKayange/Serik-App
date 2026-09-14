import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/services/location_service.dart';
import 'package:serik/services/google_maps_routing_service.dart' as routing;
import 'package:serik/services/voice_navigation_service.dart';

/// Production-grade Google Maps navigation screen
/// Features: Real Google routing, turn-by-turn, voice guidance, off-route detection, rerouting
class GoogleMapsNavigationScreen extends StatefulWidget {
  final RentalSpot destination;
  final geo.Position? currentPosition;

  const GoogleMapsNavigationScreen({
    super.key,
    required this.destination,
    this.currentPosition,
  });

  @override
  State<GoogleMapsNavigationScreen> createState() => _GoogleMapsNavigationScreenState();
}

class _GoogleMapsNavigationScreenState extends State<GoogleMapsNavigationScreen> {
  // Map controller
  GoogleMapController? _mapController;
  
  // Services
  final _routingService = routing.GoogleMapsRoutingService.instance;
  final _locationService = LocationService.instance;
  final _voiceService = VoiceNavigationService.instance;
  
  // State
  bool _isLoading = true;
  bool _isNavigating = false;
  bool _isRerouting = false;
  bool _isCameraFollowing = true;
  bool _isMuted = false;
  
  // Route data
  routing.RouteOption? _selectedRoute;
  int _currentStepIndex = 0;
  double _remainingDistance = 0.0;
  double _remainingDuration = 0.0;
  double _currentSpeed = 0.0;
  double _journeyProgress = 0.0;
  DateTime? _estimatedArrivalTime;
  
  // UI State
  bool _userInteractedWithMap = false;
  Timer? _interactionResetTimer;
  
  // Direction arrow - true rotating arrow
  double _currentHeading = 0.0;
  double _smoothedHeading = 0.0;
  final double _headingSmoothingFactor = 0.3;
  
  // Location subscription
  StreamSubscription<geo.Position>? _positionSubscription;
  
  // Off-route detection
  final double _offRouteThreshold = 50.0; // meters
  Timer? _offRouteCheckTimer;
  
  // Camera throttling
  DateTime? _lastCameraUpdate;
  static const _cameraUpdateInterval = Duration(milliseconds: 500);
  
  // Map elements
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }
  
  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
  
  Future<void> _initializeNavigation() async {
    try {
      // Initialize voice service
      await _voiceService.initialize(language: 'en-US');
      
      // Get current position
      geo.Position? position;
      if (widget.currentPosition != null) {
        position = widget.currentPosition;
      } else {
        position = await _locationService.getCurrentPosition();
      }
      
      if (position == null) {
        _showError('Could not get current location');
        return;
      }
      
      setState(() => _isLoading = true);
      
      // Request route
      if (!_routingService.isAvailable) {
        _showError('Google Maps API not configured');
        return;
      }
      
      final routeResult = await _routingService.getRoute(
        originLat: position.latitude,
        originLng: position.longitude,
        destinationLat: widget.destination.latitude,
        destinationLng: widget.destination.longitude,
      );
      
      setState(() {
        _selectedRoute = routeResult.selectedOption;
        _isLoading = false;
      });
      
      // Fit camera to route
      _fitCameraToRoute();
      
    } catch (e) {
      _showError('Navigation initialization failed: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  Future<void> _startNavigation() async {
    if (_selectedRoute == null) return;
    
    setState(() => _isNavigating = true);
    
    // Start position tracking
    await _locationService.startPositionTracking(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 5,
    );
    
    _positionSubscription = _locationService.positionStream.listen(
      _onPositionUpdate,
      onError: (error) {
        debugPrint('Position stream error: $error');
      },
    );
    
    // Start off-route checking
    _startOffRouteDetection();
    
    // Speak first instruction
    final firstStep = _currentStep;
    if (firstStep != null) {
      await _voiceService.speakWithDistance(firstStep.instruction, firstStep.distanceMeters);
    }
  }
  
  routing.NavigationStep? get _currentStep {
    if (_selectedRoute == null || _currentStepIndex >= _selectedRoute!.steps.length) {
      return null;
    }
    return _selectedRoute!.steps[_currentStepIndex];
  }
  
  routing.NavigationStep? get _nextStep {
    if (_selectedRoute == null || _currentStepIndex + 1 >= _selectedRoute!.steps.length) {
      return null;
    }
    return _selectedRoute!.steps[_currentStepIndex + 1];
  }
  
  void _onPositionUpdate(geo.Position position) {
    if (!_isNavigating) return;
    
    // Update speed
    setState(() => _currentSpeed = position.speed * 3.6);
    
    // Smooth heading for direction arrow
    _updateSmoothedHeading(position);
    
    // Update navigation
    _updateNavigation(position);
    
    // Update camera if following (throttled)
    if (_isCameraFollowing && !_userInteractedWithMap) {
      _updateCameraThrottled(position);
    }
    
    // Check arrival
    _checkArrival(position);
  }
  
  void _updateSmoothedHeading(geo.Position position) {
    if (position.speed < 0.5) {
      return;
    }
    
    final newHeading = position.heading;
    final headingDiff = (newHeading - _currentHeading).abs();
    
    if (headingDiff > 90 && headingDiff < 270) {
      return;
    }
    
    _currentHeading = newHeading;
    
    if (_smoothedHeading == 0) {
      _smoothedHeading = newHeading;
    } else {
      double diff = newHeading - _smoothedHeading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      _smoothedHeading = (_smoothedHeading + diff * _headingSmoothingFactor) % 360;
      if (_smoothedHeading < 0) _smoothedHeading += 360;
    }
  }
  
  void _updateNavigation(geo.Position position) {
    final currentStep = _currentStep;
    if (currentStep == null) return;
    
    // Calculate distance to current step
    final distanceToStep = _locationService.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.latitude,
      currentStep.longitude,
    );
    
    // Calculate remaining distance
    double remainingDistance = distanceToStep;
    for (int i = _currentStepIndex + 1; i < _selectedRoute!.steps.length; i++) {
      remainingDistance += _selectedRoute!.steps[i].distanceMeters;
    }
    
    // Calculate progress
    final totalDistance = _selectedRoute!.distanceKm * 1000;
    final progress = (1 - (remainingDistance / totalDistance)).clamp(0.0, 1.0);
    
    // Calculate ETA based on current speed
    double speed = position.speed * 3.6;
    if (speed < 1) speed = 5;
    final remainingDuration = (remainingDistance / 1000) / speed * 3600;
    final eta = DateTime.now().add(Duration(seconds: remainingDuration.round()));
    
    setState(() {
      _remainingDistance = remainingDistance;
      _remainingDuration = remainingDuration;
      _journeyProgress = progress;
      _estimatedArrivalTime = eta;
    });
    
    // Check if we've passed the current step
    if (distanceToStep < 15) {
      _advanceToNextStep();
    }
    
    // Voice announcement at appropriate distance
    _handleVoiceAnnouncement(distanceToStep, currentStep);
  }
  
  void _handleVoiceAnnouncement(double distanceToStep, routing.NavigationStep currentStep) {
    if (_currentSpeed < 1) return;
    
    if (distanceToStep < 200 && distanceToStep > 180) {
      _voiceService.speakWithDistance(currentStep.instruction, distanceToStep);
    }
    
    if (distanceToStep < 50 && distanceToStep > 30) {
      _voiceService.speak(currentStep.instruction);
    }
  }
  
  void _advanceToNextStep() {
    if (_currentStepIndex < _selectedRoute!.steps.length - 1) {
      setState(() => _currentStepIndex++);
      
      final nextStep = _currentStep;
      if (nextStep != null) {
        _voiceService.speakWithDistance(nextStep.instruction, nextStep.distanceMeters);
      }
    }
  }
  
  void _checkArrival(geo.Position position) {
    final distanceToDestination = _locationService.distanceBetween(
      position.latitude,
      position.longitude,
      widget.destination.latitude,
      widget.destination.longitude,
    );
    
    if (distanceToDestination < 30 && position.accuracy < 30) {
      _onArrived();
    }
  }
  
  void _onArrived() {
    _positionSubscription?.cancel();
    _offRouteCheckTimer?.cancel();
    _locationService.stopPositionTracking();
    _voiceService.stop();
    
    setState(() => _isNavigating = false);
    
    _voiceService.speakArrival(widget.destination.brandName);
    
    if (mounted) {
      _showArrivalDialog();
    }
  }
  
  void _startOffRouteDetection() {
    _offRouteCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isNavigating || _isRerouting) return;
      
      final position = _locationService.currentPosition;
      if (position == null) return;
      
      final distanceFromRoute = _calculateDistanceFromRoute(position);
      final accuracyThreshold = math.max(_offRouteThreshold, position.accuracy * 1.5);
      
      if (distanceFromRoute > accuracyThreshold && position.accuracy < 50) {
        _triggerReroute();
      }
    });
  }
  
  double _calculateDistanceFromRoute(geo.Position position) {
    final route = _selectedRoute;
    if (route == null) return double.infinity;
    
    final polyline = route.decodedPolyline;
    if (polyline.isEmpty) return double.infinity;
    
    double minDistance = double.infinity;
    
    for (final point in polyline) {
      final distance = _locationService.distanceBetween(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }
  
  Future<void> _triggerReroute() async {
    if (_isRerouting) return;
    
    _isRerouting = true;
    setState(() {});
    
    _voiceService.speakRerouting();
    
    try {
      final position = _locationService.currentPosition;
      if (position == null) {
        _isRerouting = false;
        return;
      }
      
      final newRoute = await _routingService.reRoute(
        currentLat: position.latitude,
        currentLng: position.longitude,
        destinationLat: widget.destination.latitude,
        destinationLng: widget.destination.longitude,
      );
      
      setState(() {
        _selectedRoute = newRoute.selectedOption;
        _currentStepIndex = 0;
        _isRerouting = false;
      });
      
      _drawRoute(newRoute.selectedOption);
      _voiceService.clearAnnouncedInstructions();
      
    } catch (e) {
      debugPrint('Reroute failed: $e');
      _isRerouting = false;
    }
  }
  
  void _updateCameraThrottled(geo.Position position) {
    final now = DateTime.now();
    if (_lastCameraUpdate != null &&
        now.difference(_lastCameraUpdate!) < _cameraUpdateInterval) {
      return;
    }
    
    _lastCameraUpdate = now;
    _updateCamera(position);
  }
  
  void _updateCamera(geo.Position position) {
    if (_mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18.0,
          bearing: position.heading,
          tilt: 45.0,
        ),
      ),
      duration: const Duration(milliseconds: 1000),
    );
  }
  
  void _fitCameraToRoute() {
    final route = _selectedRoute;
    if (route == null || _mapController == null) return;
    
    final polyline = route.decodedPolyline;
    if (polyline.isEmpty) return;
    
    double minLat = polyline.first.latitude;
    double maxLat = polyline.first.latitude;
    double minLng = polyline.first.longitude;
    double maxLng = polyline.first.longitude;
    
    for (final point in polyline) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
      duration: const Duration(milliseconds: 1000),
    );
  }
  
  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    await _drawDestinationMarker();
    
    if (_selectedRoute != null) {
      await _drawRoute(_selectedRoute!);
    }
  }
  
  Future<void> _drawDestinationMarker() async {
    final marker = Marker(
      markerId: const MarkerId('destination'),
      position: LatLng(
        widget.destination.latitude,
        widget.destination.longitude,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: widget.destination.brandName,
        snippet: widget.destination.location,
      ),
    );
    
    setState(() => _markers.add(marker));
  }
  
  Future<void> _drawRoute(routing.RouteOption route) async {
    final polyline = route.decodedPolyline;
    if (polyline.isEmpty) return;
    
    final polylineId = const PolylineId('route');
    
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: polylineId,
          color: Colors.blue,
          width: 8,
          points: polyline,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    });
  }
  
  void _onMapInteraction() {
    _userInteractedWithMap = true;
    _isCameraFollowing = false;
    
    _interactionResetTimer?.cancel();
    _interactionResetTimer = Timer(const Duration(seconds: 10), () {
      _userInteractedWithMap = false;
    });
  }
  
  void _recenterCamera() {
    _isCameraFollowing = true;
    _userInteractedWithMap = false;
    
    final position = _locationService.currentPosition;
    if (position != null) {
      _updateCamera(position);
    }
  }
  
  void _toggleMute() {
    _voiceService.toggleMute();
    setState(() => _isMuted = _voiceService.isMuted);
  }
  
  void _cancelNavigation() {
    _showCancelConfirmation();
  }
  
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Navigation'),
        content: const Text('Are you sure you want to cancel navigation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanup();
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('You\'ve Arrived'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.destination.brandName),
            const SizedBox(height: 8),
            Text(widget.destination.location),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanup();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _cleanup() {
    _positionSubscription?.cancel();
    _offRouteCheckTimer?.cancel();
    _interactionResetTimer?.cancel();
    _locationService.stopPositionTracking();
    _voiceService.stop();
    _mapController?.dispose();
  }
  
  String get _formattedCurrentSpeed {
    return '${_currentSpeed.toStringAsFixed(0)} km/h';
  }
  
  String get _formattedRemainingDistance {
    if (_remainingDistance < 1000) {
      return '${_remainingDistance.toStringAsFixed(0)} m';
    }
    return '${(_remainingDistance / 1000).toStringAsFixed(1)} km';
  }
  
  String get _formattedRemainingDuration {
    final minutes = (_remainingDuration / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
  
  String get _formattedETA {
    if (_estimatedArrivalTime == null) return '--:--';
    return '${_estimatedArrivalTime!.hour.toString().padLeft(2, '0')}:${_estimatedArrivalTime!.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF46D39A);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.destination.latitude,
                widget.destination.longitude,
              ),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: _onMapCreated,
            tiltGesturesEnabled: true,
            compassEnabled: true,
            buildingsEnabled: true,
            onCameraIdle: _onMapInteraction,
            onCameraMoveStarted: _onMapInteraction,
            zoomGesturesEnabled: true,
          ),
          
          // Loading state
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading route...'),
                ],
              ),
            ),
          
          // Route ready - Start button
          if (!_isLoading && !_isNavigating && _selectedRoute != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildStartNavigationPanel(primaryColor, isDark),
            ),
          
          // Navigation UI
          if (_isNavigating)
            _buildNavigationUI(primaryColor, isDark),
          
          // Back button
          Positioned(
            top: 50,
            left: 16,
            child: _buildBackButton(isDark),
          ),
          
          // Re-center button
          if (_isNavigating && !_isCameraFollowing)
            Positioned(
              right: 16,
              bottom: 100,
              child: _buildRecenterButton(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStartNavigationPanel(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            widget.destination.brandName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.destination.location,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.directions_car, size: 16, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                _selectedRoute?.formattedDistance ?? '--',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: primaryColor),
              const SizedBox(width: 4),
              Text(
                _selectedRoute?.formattedDuration ?? '--',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNavigation,
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationUI(Color primaryColor, bool isDark) {
    return Stack(
      children: [
        // Top instruction panel
        Positioned(
          top: 100,
          left: 16,
          right: 16,
          child: _buildInstructionPanel(primaryColor, isDark),
        ),
        
        // Bottom info panel
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _buildBottomPanel(primaryColor, isDark),
        ),
        
        // Progress bar
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: _buildProgressBar(primaryColor, isDark),
        ),
      ],
    );
  }
  
  Widget _buildInstructionPanel(Color primaryColor, bool isDark) {
    final currentStep = _currentStep;
    final nextStep = _nextStep;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current instruction with direction arrow
          Row(
            children: [
              _buildDirectionArrow(primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep?.formattedDistance ?? '--',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentStep?.instruction ?? 'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Next instruction
          if (nextStep != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Then: ', style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Text(
                      nextStep.instruction,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDirectionArrow(Color primaryColor) {
    return Transform.rotate(
      angle: _smoothedHeading * math.pi / 180,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
  
  Widget _buildBottomPanel(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Speed
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _formattedCurrentSpeed,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _formattedRemainingDistance,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ETA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _formattedETA,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formattedRemainingDuration,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Mute button
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: _toggleMute,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelNavigation,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressBar(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${(_journeyProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _journeyProgress,
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
  
  Widget _buildRecenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: _recenterCamera,
      ),
    );
  }
}
