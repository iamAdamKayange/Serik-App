import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/pages/google_maps_navigation_screen.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/providers/auth_provider.dart';
// ignore: unused_import
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/widgets/loading_states.dart';
import 'package:serik/widgets/pull_to_refresh.dart';

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

class GoogleMapsPropertyMapPage extends StatefulWidget {
  final PropertyMapMode mode;
  final String? selectedUniversity;

  const GoogleMapsPropertyMapPage.browse({super.key, this.selectedUniversity})
    : mode = PropertyMapMode.browse;

  const GoogleMapsPropertyMapPage.landlord({super.key})
    : mode = PropertyMapMode.landlord,
      selectedUniversity = null;

  @override
  State<GoogleMapsPropertyMapPage> createState() => _GoogleMapsPropertyMapPageState();
}

class _GoogleMapsPropertyMapPageState extends State<GoogleMapsPropertyMapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'Zote';
  String _selectedUniversity = 'Zote';

  // Data
  List<HouseData> _properties = [];
  List<HouseData> _filteredProperties = [];

  // Dark mode map style
  static const String _darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#181818"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1b1b1b"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8a8a8a"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#373737"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3c3c3c"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4e4e4e"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3f3f3f"
          }
        ]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update map style when theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_mapController != null) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (isDark) {
          await _mapController!.setMapStyle(_darkMapStyle);
        } else {
          await _mapController!.setMapStyle(null);
        }
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      // Use paginated API for better performance
      final housesData = await ApiService.getAllHousesPaginated(limit: 100, offset: 0);
      
      final properties = housesData.map((json) => HouseData.fromJson(json as Map<String, dynamic>)).toList();
      
      setState(() {
        _properties = properties;
        _filteredProperties = properties;
        _isLoading = false;
      });

      await _addPropertyMarkers();
    } catch (e) {
      debugPrint('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPropertyMarkers() async {
    if (_mapController == null) return;

    final Set<Marker> markers = {};

    for (final property in _filteredProperties) {
      if (property.latitude == null || property.longitude == null) continue;
      if (property.latitude == 0.0 || property.longitude == 0.0) continue;

      // Get color based on property type
      final markerColor = _getPropertyTypeColor(property.type);
      
      // Format price compactly
      final priceLabel = _formatCompactPrice(property.rentPrice.toString());

      final marker = Marker(
        markerId: MarkerId(property.id),
        position: LatLng(property.latitude!, property.longitude!),
        onTap: () => _showPropertyBottomSheet(property),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: property.firstName.isNotEmpty ? property.firstName : property.name,
          snippet: '$priceLabel - ${property.type}',
        ),
      );

      markers.add(marker);
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  double _getPropertyTypeColor(String type) {
    final lowerType = type.toLowerCase();
    
    switch (lowerType) {
      case 'apartment':
        return BitmapDescriptor.hueBlue;
      case 'mansion':
        return BitmapDescriptor.hueMagenta;
      case 'house':
        return BitmapDescriptor.hueGreen;
      case 'studio':
        return BitmapDescriptor.hueOrange;
      case 'hostel':
        return BitmapDescriptor.hueCyan;
      case 'room':
        return BitmapDescriptor.hueYellow;
      case 'bedsitter':
        return BitmapDescriptor.hueMagenta;
      case 'single room':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  String _formatCompactPrice(String price) {
    try {
      final priceValue = double.tryParse(price) ?? 0;
      if (priceValue >= 1000000) {
        return '${(priceValue / 1000000).toStringAsFixed(1)}M';
      } else if (priceValue >= 1000) {
        return '${(priceValue / 1000).toStringAsFixed(0)}K';
      }
      return priceValue.toString();
    } catch (e) {
      return price;
    }
  }

  void _showPropertyBottomSheet(HouseData property) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isLoggedIn;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF46D39A);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final surfaceColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property image if available
                    if (property.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          property.images.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.home, size: 64, color: subtextColor),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Property name and type
                    Text(
                      property.firstName.isNotEmpty ? property.firstName : property.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.type,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Price and bedrooms
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            isDarkMode,
                            Icons.attach_money,
                            property.rentPrice > 0
                                ? 'TZS ${property.rentPrice.toStringAsFixed(0)}'
                                : 'Haijabainishwa',
                            'Bei ya mwezi',
                            primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            isDarkMode,
                            Icons.bed,
                            '${property.bedrooms}',
                            'Vyumba',
                            primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Address
                    if (property.address.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              property.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: subtextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Action buttons
                    if (isLoggedIn) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToDetails(property);
                              },
                              icon: const Icon(Icons.info_outline_rounded),
                              label: Text(
                                context.tr('Ona Zaidi', en: 'View More'),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _navigateToDirections(property);
                              },
                              icon: const Icon(Icons.navigation_rounded),
                              label: Text(
                                context.tr('Naelekea', en: 'Directions'),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Unauthenticated - show login prompt
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 40,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingia kuona maelezo kamili',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ingia ili kuona maelezo kamili ya nyumba hii',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _navigateToLogin(property);
                                },
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  context.tr('Ingia', en: 'Sign In'),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDarkMode,
    IconData icon,
    String value,
    String label,
    Color primaryColor,
  ) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetails(HouseData property) async {
    final rentalSpot = RentalSpot.fromHouseData(property);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: rentalSpot)),
      );
    }
  }

  Future<void> _navigateToDirections(HouseData property) async {
    if (!property.hasValidLocation()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Hakuna eneo la nyumba', en: 'No house location')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final currentPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      if (mounted) {
        final rentalSpot = RentalSpot.fromHouseData(property);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleMapsNavigationScreen(
              destination: rentalSpot,
              currentPosition: currentPosition,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Imeshindikana kupata eneo lako', en: 'Could not get your location')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToLogin(HouseData property) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    // Apply dark mode map style if needed
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      await controller.setMapStyle(_darkMapStyle);
    }
    
    await _addPropertyMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF46D39A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8),
      body: Stack(
        children: [
          // Map with pull-to-refresh
          CustomPullToRefresh(
            onRefresh: _loadProperties,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: const LatLng(-6.7924, 39.2083),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: _onMapCreated,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
            ),
          ),

          // Loading indicator
          if (_isLoading)
            LoadingState(
              message: context.tr('Inapakia mali...', en: 'Loading properties...'),
              variant: LoadingVariant.circular,
            ),

          // Search bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _buildSearchBar(isDark, primaryColor),
          ),

          // Filter button
          Positioned(
            top: 110,
            right: 16,
            child: _buildFilterButton(isDark, primaryColor),
          ),

          // Property count
          if (!_isLoading)
            Positioned(
              bottom: 20,
              left: 16,
              child: _buildPropertyCount(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color primaryColor) {
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.tr('Tafuta mali...', en: 'Search properties...'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _filteredProperties = _properties;
              });
              _addPropertyMarkers();
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
            _filteredProperties = _properties.where((p) {
              return p.name.toLowerCase().contains(_searchQuery) ||
                     p.location.toLowerCase().contains(_searchQuery);
            }).toList();
          });
          _addPropertyMarkers();
        },
      ),
    );
  }

  Widget _buildFilterButton(bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.filter_list, color: Colors.white),
        onPressed: () => _showFilterDialog(isDark, primaryColor),
      ),
    );
  }

  Widget _buildPropertyCount(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        context.tr('${_filteredProperties.length} mali', en: '${_filteredProperties.length} properties'),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFilterDialog(bool isDark, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Chuja Mali', en: 'Filter Properties')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(labelText: context.tr('Aina ya Mali', en: 'Property Type')),
              items: [
                DropdownMenuItem(value: 'Zote', child: Text(context.tr('Zote', en: 'All'))),
                DropdownMenuItem(value: 'Studio', child: Text('Studio')),
                DropdownMenuItem(value: '1 Bedroom', child: Text(context.tr('Chumba 1', en: '1 Bedroom'))),
                DropdownMenuItem(value: '2 Bedroom', child: Text(context.tr('Chumba 2', en: '2 Bedroom'))),
                DropdownMenuItem(value: '3+ Bedroom', child: Text(context.tr('Chumba 3+', en: '3+ Bedroom'))),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedUniversity,
              decoration: InputDecoration(labelText: context.tr('Chuo Kikuu', en: 'University')),
              items: [
                DropdownMenuItem(value: 'Zote', child: Text(context.tr('Vyuo Vyote', en: 'All Universities'))),
                DropdownMenuItem(value: 'UDOM', child: Text('UDOM')),
                DropdownMenuItem(value: 'UDSM', child: Text('UDSM')),
                DropdownMenuItem(value: 'MUST', child: Text('MUST')),
                DropdownMenuItem(value: 'DIT', child: Text('DIT')),
                DropdownMenuItem(value: 'CBE', child: Text('CBE')),
                DropdownMenuItem(value: 'SUA', child: Text('SUA')),
                DropdownMenuItem(value: 'IFM', child: Text('IFM')),
              ],
              onChanged: (value) {
                setState(() => _selectedUniversity = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = 'Zote';
                _selectedUniversity = 'Zote';
                _filteredProperties = _properties;
              });
              _addPropertyMarkers();
              Navigator.pop(context);
            },
            child: Text(context.tr('Wacha Macho', en: 'Clear Filters')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Ghairi', en: 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: Text(context.tr('Weka', en: 'Apply')),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredProperties = _properties.where((p) {
        // Type filter
        if (_selectedType != 'Zote') {
          final typeMatch = _selectedType.toLowerCase();
          if (typeMatch == '1 bedroom' && p.bedrooms != 1) return false;
          if (typeMatch == '2 bedroom' && p.bedrooms != 2) return false;
          if (typeMatch == '3+ bedroom' && p.bedrooms < 3) return false;
          if (typeMatch == 'studio' && p.type.toLowerCase() != 'studio') return false;
        }

        // University filter
        if (_selectedUniversity != 'Zote') {
          final university = _universities.firstWhere(
            (u) => u['name'] == _selectedUniversity,
            orElse: () => {'name': '', 'lat': 0.0, 'lng': 0.0, 'radius_km': 0.0},
          );
          if (university['name'] != '') {
            if (p.latitude == null || p.longitude == null) return false;
            final distance = _calculateDistance(
              p.latitude!,
              p.longitude!,
              university['lat'] as double,
              university['lng'] as double,
            );
            if (distance > (university['radius_km'] as num).toDouble()) {
              return false;
            }
          }
        }

        return true;
      }).toList();
    });
    _addPropertyMarkers();
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
