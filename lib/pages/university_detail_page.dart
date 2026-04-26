// lib/screen/university_detail_page.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:serkapp/model/rental_model.dart';
import 'package:serkapp/screen/rental_detail_screen.dart';
import 'package:serkapp/services/api_services.dart';

class UniversityDetailPage extends StatefulWidget {
  final Map<String, dynamic> university;

  const UniversityDetailPage({super.key, required this.university});

  @override
  State<UniversityDetailPage> createState() => _UniversityDetailPageState();
}

class _UniversityDetailPageState extends State<UniversityDetailPage> {
  List<RentalSpot> _nearbySpots = [];
  List<RentalSpot> _allSpots = [];
  bool _isLoading = true;
  double _currentRadius = 2.0; // Default radius 2km

  // Haversine formula - Kuhesabu umbali halisi kati ya pointi mbili
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Radius ya dunia kwa Kilomita

    // Badilisha degrees kuwa Radians
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLng = (lng2 - lng1) * (pi / 180);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  void initState() {
    super.initState();
    _currentRadius = widget.university['radius_km'] ?? 2.0;
    _loadNearbySpotsFromAPI();
  }

  // 🔥 NEW: Load from API instead of local database
  Future<void> _loadNearbySpotsFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
        '📍 Loading rental spots from API for ${widget.university['name']}...',
      );

      // Get all rental spots from API
      final allSpots = await ApiService.getAllRentalSpots();

      debugPrint('✅ Loaded ${allSpots.length} rental spots from API');

      setState(() {
        _allSpots = allSpots;
      });

      _filterNearbySpots();
    } catch (e) {
      debugPrint('❌ Error loading rental spots: $e');
      setState(() {
        _isLoading = false;
      });
      _showError("Hitilafu katika kupakua nyumba: $e");
    }
  }

  // 🔥 NEW: Filter spots based on current radius
  void _filterNearbySpots() {
    // Get university coordinates
    double uniLat = widget.university['lat'] ?? 0.0;
    double uniLng = widget.university['lng'] ?? 0.0;

    List<RentalSpot> nearby = [];

    for (var spot in _allSpots) {
      // Skip spots without valid coordinates
      if (!spot.hasValidLocation()) continue;

      // Calculate distance between university and house
      double distance = _calculateDistance(
        uniLat,
        uniLng,
        spot.latitude,
        spot.longitude,
      );

      // Add to list if within radius
      if (distance <= _currentRadius) {
        nearby.add(spot);
      }
    }

    // Sort by distance (nearest first)
    nearby.sort((a, b) {
      double distA = _calculateDistance(
        uniLat,
        uniLng,
        a.latitude,
        a.longitude,
      );
      double distB = _calculateDistance(
        uniLat,
        uniLng,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });

    setState(() {
      _nearbySpots = nearby;
      _isLoading = false;
    });

    debugPrint(
      '📍 Found ${nearby.length} houses within ${_currentRadius}km of ${widget.university['name']}',
    );
  }

  // 🔥 MODIFIED: Show rental details using RentalSpot
  void _showRentalDetails(RentalSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: spot)),
    );
  }

  // 🔥 MODIFIED: Get distance text using RentalSpot
  String _getDistanceText(RentalSpot spot) {
    double uniLat = widget.university['lat'] ?? 0.0;
    double uniLng = widget.university['lng'] ?? 0.0;

    if (!spot.hasValidLocation()) {
      return "Umbali haujulikani";
    }

    double distance = _calculateDistance(
      uniLat,
      uniLng,
      spot.latitude,
      spot.longitude,
    );

    if (distance < 1.0) {
      return "🏃 ${(distance * 1000).toInt()} m";
    } else {
      return "🚗 ${distance.toStringAsFixed(1)} km";
    }
  }

  // Dialog ya kubadilisha radius
  void _showRadiusDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double tempRadius = _currentRadius;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Badilisha Umbali wa Utafutaji',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempRadius,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    label: '${tempRadius.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setStateSheet(() {
                        tempRadius = value;
                      });
                    },
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Umbali: ${tempRadius.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Ghairi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _currentRadius = tempRadius;
                            });
                            Navigator.pop(context);
                            _filterNearbySpots(); // Re-filter with new radius
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          child: const Text('Tumia'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔥 MODIFIED: Build house card using RentalSpot
  Widget _buildHouseCard(RentalSpot spot, int index) {
    // Calculate distance for this house
    double uniLat = widget.university['lat'] ?? 0.0;
    double uniLng = widget.university['lng'] ?? 0.0;
    double distance = _calculateDistance(
      uniLat,
      uniLng,
      spot.latitude,
      spot.longitude,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showRentalDetails(spot),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // House Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: spot.hasImages()
                        ? DecorationImage(
                            image: FileImage(File(spot.getFirstImage()!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: !spot.hasImages()
                      ? Center(
                          child: Icon(
                            Icons.home_rounded,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // House Name
                      Text(
                        spot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Address (using RentalSpot helper)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spot.getShortAddress(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Distance Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: distance < 1.0
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              distance < 1.0
                                  ? Icons.directions_walk
                                  : Icons.directions_car,
                              size: 12,
                              color: distance < 1.0
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDistanceText(spot),
                              style: TextStyle(
                                fontSize: 11,
                                color: distance < 1.0
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Type and Bedrooms
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              spot.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${spot.bedrooms} Vyumba",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price and Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${spot.formattedPrice}/mwezi",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: spot.status == 'Inapatikana'
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                spot.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.university['name']),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // Filter radius button
          IconButton(
            icon: const Icon(Icons.radio_button_checked_outlined),
            onPressed: _showRadiusDialog,
            tooltip: 'Badilisha umbali',
          ),
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Nyumba ${_nearbySpots.length} zilizopo karibu na ${widget.university['name']} ndani ya km ${_currentRadius.toStringAsFixed(1)}",
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Taarifa',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(bottom: BorderSide(color: Colors.green[100]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.home_work_outlined,
                  "Nyumba",
                  _nearbySpots.length.toString(),
                  const Color(0xFF2E7D32),
                ),
                _buildStatItem(
                  Icons.straighten,
                  "Radius",
                  "${_currentRadius.toStringAsFixed(1)} km",
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.location_on,
                  "Umbali",
                  _nearbySpots.isNotEmpty
                      ? _getDistanceText(_nearbySpots.first)
                      : "N/A",
                  Colors.blue,
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // University Header Image
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: widget.university['image'] != null
                          ? DecorationImage(
                              image: NetworkImage(widget.university['image']),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.green[800],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.university['name'],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.university['rating']
                                                  ?.toString() ??
                                              "4.5",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Radius: ${_currentRadius.toStringAsFixed(1)} km",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // University Description
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kuhusu ${widget.university['name']}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.university['desc'] ??
                                    "Chuo kikuu kinachojulikana kwa elimu bora na mazingira mazuri ya kujifunzia. Iko katika eneo zuri la kutafuta nyumba za kupanga.",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nearby Houses Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Nyumba Zilizopo Karibu",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${_nearbySpots.length} zimepatikana",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Loading Indicator
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        // No Houses Message
                        if (!_isLoading && _nearbySpots.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Hakuna nyumba karibu na chuo hiki",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Jaribu kuongeza radius kutoka km ${_currentRadius.toStringAsFixed(1)} hadi zaidi",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _showRadiusDialog,
                                  icon: const FaIcon(FontAwesomeIcons.radio),
                                  label: const Text('Badilisha Umbali'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Houses List
                        if (!_isLoading && _nearbySpots.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _nearbySpots.length,
                            itemBuilder: (context, index) {
                              return _buildHouseCard(
                                _nearbySpots[index],
                                index,
                              );
                            },
                          ),

                        const SizedBox(height: 30),

                        // Call to Action
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[700]!, Colors.green[500]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Unatafuta nyumba karibu na ${widget.university['name']}?",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Wasiliana nasi kwa kupanga nyumba au kuweka nyumba yako kwa ajili ya kupangisha",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Navigate to map page with this university
                                        Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Tafuta Nyumba"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () {
                                        // Navigate to add house page
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Bonyeza + kwenye dashboard kuweka nyumba",
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Weka Nyumba"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
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

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
