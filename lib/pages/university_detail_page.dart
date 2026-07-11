import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/model/rental_model.dart';
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/pages/login_page.dart';
import 'package:serkapp/providers/auth_provider.dart';
import 'package:serkapp/providers/theme_provider.dart';
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
  bool _hasError = false;
  String _errorMessage = "";
  double _currentRadius = 2.0;

  bool get isDarkMode =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  Color get primaryColor =>
      isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF121212) : Colors.grey[50]!;
  Color get surfaceColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subtextColor => isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get borderColor => isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;
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
    _currentRadius = widget.university['radius_km']?.toDouble() ?? 2.0;
    _loadNearbySpots();
  }

  Future<void> _loadNearbySpots() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = "";
    });

    try {
      debugPrint(
        '📍 Loading houses from backend for ${widget.university['name']}...',
      );
      final List<dynamic> housesJson = await ApiService.getAllHouses();
      final List<RentalSpot> allSpots = housesJson.map((json) {
        final houseData = HouseData.fromJson(json as Map<String, dynamic>);
        return RentalSpot.fromHouseData(houseData);
      }).toList();
      debugPrint('✅ Loaded ${allSpots.length} houses');

      setState(() => _allSpots = allSpots);
      _filterNearbySpots();
    } catch (e) {
      debugPrint('❌ Error loading houses: $e');
      String userMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        userMessage =
            "Hakuna muunganisho wa mtandao. Tafadhali angalia intaneti yako.";
      } else if (e.toString().contains('timeout')) {
        userMessage = "Muunganisho umechukua muda mrefu. Jaribu tena.";
      } else {
        userMessage = "Hitilafu katika kupakua nyumba. Jaribu tena baadaye.";
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = userMessage;
      });
    }
  }

  void _filterNearbySpots() {
    double uniLat = widget.university['lat']?.toDouble() ?? 0.0;
    double uniLng = widget.university['lng']?.toDouble() ?? 0.0;
    List<RentalSpot> nearby = [];

    for (var spot in _allSpots) {
      if (!spot.hasValidLocation()) continue;
      double distance = _calculateDistance(
        uniLat,
        uniLng,
        spot.latitude,
        spot.longitude,
      );
      if (distance <= _currentRadius) nearby.add(spot);
    }

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
      _hasError = false;
    });

    debugPrint(
      '📍 Found ${nearby.length} houses within ${_currentRadius}km of ${widget.university['name']}',
    );
  }

  void _showRentalDetails(RentalSpot spot) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: spot)),
    );
  }

  void _showLoginPrompt() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.loginRequired),
        content: Text(l10n.loginRequiredDetails),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }

  String _getDistanceText(RentalSpot spot) {
    double uniLat = widget.university['lat']?.toDouble() ?? 0.0;
    double uniLng = widget.university['lng']?.toDouble() ?? 0.0;
    if (!spot.hasValidLocation()) return "Umbali haujulikani";
    double distance = _calculateDistance(
      uniLat,
      uniLng,
      spot.latitude,
      spot.longitude,
    );
    if (distance < 1.0) return "🏃 ${(distance * 1000).toInt()} m";
    return "🚗 ${distance.toStringAsFixed(1)} km";
  }

  void _showRadiusDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double tempRadius = _currentRadius;
        return StatefulBuilder(
          builder: (context, setStateSheet) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Badilisha Umbali wa Utafutaji',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: tempRadius,
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  label: '${tempRadius.toStringAsFixed(1)} km',
                  onChanged: (value) => setStateSheet(() => tempRadius = value),
                  activeColor: primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Umbali: ${tempRadius.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                          side: BorderSide(
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: const Text('Ghairi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _currentRadius = tempRadius);
                          Navigator.pop(context);
                          _filterNearbySpots();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: const Text('Tumia'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHouseCard(RentalSpot spot, int index) {
    final isLoggedIn = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).isLoggedIn;
    final l10n = AppLocalizations.of(context);
    double uniLat = widget.university['lat']?.toDouble() ?? 0.0;
    double uniLng = widget.university['lng']?.toDouble() ?? 0.0;
    double distance = _calculateDistance(
      uniLat,
      uniLng,
      spot.latitude,
      spot.longitude,
    );

    final String? thumbnail = spot.videoThumbnails.isNotEmpty
        ? spot.videoThumbnails.first
        : (spot.hasImages() ? spot.getFirstImage() : null);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showRentalDetails(spot),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      child: thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: thumbnail,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                placeholder: (_, _) => Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 30,
                                    color: isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.home_rounded,
                                size: 35,
                                color: isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                    ),
                    if (spot.videos.isNotEmpty)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.videocam,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? spot.brandName : l10n.houseNearCampus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isLoggedIn
                                  ? spot.getShortAddress()
                                  : l10n.hiddenLocation,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: distance < 1.0
                              ? (isDarkMode
                                    ? Colors.green[900]
                                    : Colors.green[50])
                              : (isDarkMode
                                    ? Colors.orange[900]
                                    : Colors.orange[50]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              distance < 1.0
                                  ? Icons.directions_walk
                                  : Icons.directions_car,
                              size: 10,
                              color: distance < 1.0
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLoggedIn
                                  ? _getDistanceText(spot)
                                  : l10n.hiddenDistance,
                              style: TextStyle(
                                fontSize: 10,
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
                      Row(
                        children: [
                          Text(
                            isLoggedIn ? spot.formattedPrice : l10n.hiddenPrice,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          if (isLoggedIn)
                            Text(
                              '/mwezi',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: !isLoggedIn
                                  ? Colors.grey
                                  : (spot.status == 'Inapatikana'
                                        ? Colors.green
                                        : Colors.orange),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              !isLoggedIn
                                  ? l10n.loginStatus
                                  : (spot.status == 'Inapatikana'
                                        ? 'Inapatikana'
                                        : 'Imekodishwa'),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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

  // 🔥 Helper to build header image (supports both asset and network)
  Widget _buildHeaderImage() {
    final String? imagePath = widget.university['image'];
    final bool isAsset = imagePath != null && imagePath.startsWith('assets/');

    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        color: primaryColor.withValues(alpha: 0.2),
        child: Center(
          child: Icon(Icons.school_rounded, size: 80, color: primaryColor),
        ),
      );
    }

    if (isAsset) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: double.infinity,
          height: 200,
          color: primaryColor.withValues(alpha: 0.2),
          child: Center(
            child: Icon(Icons.broken_image, size: 60, color: primaryColor),
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: double.infinity,
          height: 200,
          color: primaryColor.withValues(alpha: 0.1),
          child: Center(child: CircularProgressIndicator(color: primaryColor)),
        ),
        errorWidget: (_, _, _) => Container(
          width: double.infinity,
          height: 200,
          color: primaryColor.withValues(alpha: 0.2),
          child: Center(
            child: Icon(Icons.broken_image, size: 60, color: primaryColor),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.university['name'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.radio_button_checked_outlined),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _showRadiusDialog,
            tooltip: 'Badilisha umbali',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Nyumba ${_nearbySpots.length} zilizopo karibu na ${widget.university['name']} ndani ya km ${_currentRadius.toStringAsFixed(1)}",
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: isDarkMode ? Colors.grey[800] : null,
                ),
              );
            },
            tooltip: 'Taarifa',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.white : Colors.black).withValues(
                    alpha: 0.02,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.home_work_outlined,
                  "Nyumba",
                  _nearbySpots.length.toString(),
                  primaryColor,
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNearbySpots,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header image (supports asset and network)
                    Stack(
                      children: [
                        _buildHeaderImage(),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                isDarkMode
                                    ? Colors.black.withValues(alpha: 0.85)
                                    : Colors.black.withValues(alpha: 0.7),
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
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 14,
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
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          "Radius: ${_currentRadius.toStringAsFixed(1)} km",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
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
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isDarkMode ? Colors.white : Colors.black)
                                          .withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.school_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Kuhusu ${widget.university['name']}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.university['desc'] ??
                                      "Chuo kikuu kinachojulikana kwa elimu bora na mazingira mazuri ya kujifunzia. Iko katika eneo zuri la kutafuta nyumba za kupanga.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subtextColor,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Nyumba Zilizopo Karibu",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${_nearbySpots.length}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildQuickFilterChip('Karibu Sana', () {
                                  setState(() => _currentRadius = 0.5);
                                  _filterNearbySpots();
                                }),
                                const SizedBox(width: 8),
                                _buildQuickFilterChip('1 km', () {
                                  setState(() => _currentRadius = 1.0);
                                  _filterNearbySpots();
                                }),
                                const SizedBox(width: 8),
                                _buildQuickFilterChip('2 km', () {
                                  setState(() => _currentRadius = 2.0);
                                  _filterNearbySpots();
                                }),
                                const SizedBox(width: 8),
                                _buildQuickFilterChip('3 km', () {
                                  setState(() => _currentRadius = 3.0);
                                  _filterNearbySpots();
                                }),
                                const SizedBox(width: 8),
                                _buildQuickFilterChip('5 km', () {
                                  setState(() => _currentRadius = 5.0);
                                  _filterNearbySpots();
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Error state with retry button
                          if (!_isLoading && _hasError)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.wifi_off,
                                      size: 60,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: subtextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _loadNearbySpots,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Jaribu Tena'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Loading indicator
                          if (_isLoading)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                            ),

                          // No houses message (only when no error and not loading)
                          if (!_isLoading && !_hasError && _nearbySpots.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
                                    size: 60,
                                    color: isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Hakuna nyumba karibu na chuo hiki",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: subtextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Jaribu kuongeza radius kutoka km ${_currentRadius.toStringAsFixed(1)} hadi zaidi",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _showRadiusDialog,
                                    icon: const Icon(Icons.zoom_out_map),
                                    label: const Text('Ongeza Umbali'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Houses list
                          if (!_isLoading &&
                              !_hasError &&
                              _nearbySpots.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _nearbySpots.length,
                              itemBuilder: (context, index) =>
                                  _buildHouseCard(_nearbySpots[index], index),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      onSelected: (_) => onTap(),
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      selectedColor: primaryColor,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDarkMode ? Colors.white70 : Colors.black87,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.grey[400] : Colors.grey,
          ),
        ),
      ],
    );
  }
}
