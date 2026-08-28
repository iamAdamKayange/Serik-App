import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/pages/custom_map_page.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/pages/app_settings_page.dart';
import 'package:serik/pages/profile_edit_page.dart';
import 'package:serik/pages/notification_screen.dart';
import 'package:serik/pages/rental_home_page.dart';
import 'package:serik/pages/university_detail_page.dart';
import 'package:serik/pages/video_feed_page.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/services/realtime_service.dart';
import 'package:serik/widgets/saved_house_button.dart';

class HomePage extends StatefulWidget {
  final Function()? onHouseAdded;
  const HomePage({super.key, this.onHouseAdded});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> universities = [
    {
      "name": "UDOM",
      "shortName": "UDOM",
      "lat": -6.21630,
      "lng": 35.7419,
      "radius_km": 2.5,
      "city": "Dodoma",
      "desc": "Nyumba za kisasa karibu na Chuo Kikuu cha Dodoma",
      "image":
          "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=800&q=80",
      "houses": 45,
      "rating": 4.8,
    },
    {
      "name": "UDSM",
      "shortName": "UDSM",
      "lat": -6.7816,
      "lng": 39.20567,
      "radius_km": 3.0,
      "city": "Dar es Salaam",
      "desc": "Nyumba na vyumba bora karibu na Chuo Kikuu cha Dar es Salaam",
      "image":
          "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=800&q=80",
      "houses": 38,
      "rating": 4.9,
    },
    {
      "name": "MUST",
      "shortName": "MUST",
      "lat": -8.909401,
      "lng": 33.460773,
      "radius_km": 2.0,
      "city": "Mbeya",
      "desc": "Makazi nafuu karibu na Mbeya University of Science & Tech",
      "image":
          "https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=800&q=80",
      "houses": 22,
      "rating": 4.6,
    },
    {
      "name": "DIT",
      "shortName": "DIT",
      "lat": -6.8144,
      "lng": 39.2833,
      "radius_km": 2.0,
      "city": "Dar es Salaam",
      "desc": "Vyumba na apartments karibu na DIT Posta",
      "image":
          "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80",
      "houses": 28,
      "rating": 4.5,
    },
    {
      "name": "CBE",
      "shortName": "CBE",
      "lat": -6.1736,
      "lng": 35.7410,
      "radius_km": 2.0,
      "city": "Dodoma",
      "desc": "Pata nyumba za kisasa karibu na CBE Dodoma",
      "image":
          "https://images.unsplash.com/photo-1498243691581-b145c3f54a5a?auto=format&fit=crop&w=800&q=80",
      "houses": 30,
      "rating": 4.7,
    },
    {
      "name": "SUA",
      "shortName": "SUA",
      "lat": -6.6999,
      "lng": 36.6936,
      "radius_km": 2.5,
      "city": "Morogoro",
      "desc": "Nyumba za kupanga karibu na SUA Morogoro",
      "image":
          "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=800&q=80",
      "houses": 32,
      "rating": 4.7,
    },
    {
      "name": "IFM",
      "shortName": "IFM",
      "lat": -6.81395,
      "lng": 39.29366,
      "radius_km": 2.0,
      "city": "Dar es Salaam",
      "desc": "Makazi bora karibu na IFM & Posta",
      "image":
          "https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80",
      "houses": 25,
      "rating": 4.4,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<RentalSpot> _allRentalSpots = [];
  List<RentalSpot> _filteredSpots = [];
  bool _isLoading = true;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedCategory =
      'all'; // all, apartments, campus, full, videos, budget
  String _selectedUniversity = 'Zote';
  int _currentIndex = 0;
  bool _isGridView = false;

  // Filter criteria
  int? _filterBedrooms;
  double? _minPrice;
  double? _maxPrice;
  String _sortOption = 'default';

  late final RealtimeCallback _houseChangeListener;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadHouses();
    _houseChangeListener = (_) {
      if (!mounted) return;
      _loadHouses();
    };
    RealtimeService.instance.on('house:changed', _houseChangeListener);
  }

  @override
  void dispose() {
    RealtimeService.instance.off('house:changed', _houseChangeListener);
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _initializeSpeech() async {
    try {
      await _speech.initialize();
    } catch (_) {}
  }

  void _startListening() {
    if (_isListening) return;
    _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _applyFilters();
        });
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _loadHouses() async {
    setState(() => _isLoading = true);
    try {
      final housesData = await ApiService.getAllHouses();
      if (!mounted) return;
      final spots = housesData.map((json) {
        final house = HouseData.fromJson(json as Map<String, dynamic>);
        return RentalSpot.fromHouseData(house);
      }).toList();

      setState(() {
        _allRentalSpots = spots;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading houses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool _isNearUniversity(RentalSpot spot, Map<String, dynamic> university) {
    if (!spot.hasValidLocation()) return false;
    final distance = _calculateDistance(
      (university['lat'] as num).toDouble(),
      (university['lng'] as num).toDouble(),
      spot.latitude,
      spot.longitude,
    );
    return distance <= (university['radius_km'] as num).toDouble();
  }

  void _applyFilters() {
    List<RentalSpot> result = List.from(_allRentalSpots);

    // Search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((spot) {
        final nameMatch = spot.brandName.toLowerCase().contains(query);
        final locMatch =
            spot.location.toLowerCase().contains(query) ||
            spot.address.toLowerCase().contains(query) ||
            spot.region.toLowerCase().contains(query) ||
            spot.district.toLowerCase().contains(query) ||
            spot.street.toLowerCase().contains(query);
        final typeMatch = spot.type.toLowerCase().contains(query);
        return nameMatch || locMatch || typeMatch;
      }).toList();
    }

    // Category filter
    if (_selectedCategory == 'apartments') {
      result = result
          .where((s) => s.type.toLowerCase().contains('apartment'))
          .toList();
    } else if (_selectedCategory == 'campus') {
      result = result.where((s) {
        return universities.any((u) => _isNearUniversity(s, u));
      }).toList();
    } else if (_selectedCategory == 'videos') {
      result = result.where((s) => s.videos.isNotEmpty).toList();
    } else if (_selectedCategory == 'budget') {
      result = result.where((s) => s.rentPrice <= 250000).toList();
    }

    // University filter
    if (_selectedUniversity != 'Zote') {
      final uni = universities.firstWhere(
        (u) => u['name'] == _selectedUniversity,
        orElse: () => {},
      );
      if (uni.isNotEmpty) {
        result = result.where((s) => _isNearUniversity(s, uni)).toList();
      }
    }

    // Bedrooms
    if (_filterBedrooms != null) {
      result = result.where((s) => s.bedrooms == _filterBedrooms).toList();
    }

    // Price range
    if (_minPrice != null) {
      result = result.where((s) => s.rentPrice >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      result = result.where((s) => s.rentPrice <= _maxPrice!).toList();
    }

    // Sort
    if (_sortOption == 'price_asc') {
      result.sort((a, b) => a.rentPrice.compareTo(b.rentPrice));
    } else if (_sortOption == 'price_desc') {
      result.sort((a, b) => b.rentPrice.compareTo(a.rentPrice));
    }

    setState(() {
      _filteredSpots = result;
    });
  }

  void _showFilterModal(bool isDark, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chuja Nyumba & Bei',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateModal(() {
                              _filterBedrooms = null;
                              _minPrice = null;
                              _maxPrice = null;
                              _sortOption = 'default';
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Weka Upya'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bedrooms
                    Text(
                      'Idadi ya Vyumba:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [null, 1, 2, 3, 4].map((beds) {
                        final isSelected = _filterBedrooms == beds;
                        final label = beds == null ? 'Zote' : '$beds Vyumba';
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            setStateModal(() {
                              _filterBedrooms = beds;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Sorting
                    Text(
                      'Panga kwa Bei:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSortButton(
                          'Chaguo Msingi',
                          'default',
                          _sortOption,
                          isDark,
                          primaryColor,
                          (v) => setStateModal(() => _sortOption = v),
                        ),
                        const SizedBox(width: 8),
                        _buildSortButton(
                          'Bei: Chini ↗',
                          'price_asc',
                          _sortOption,
                          isDark,
                          primaryColor,
                          (v) => setStateModal(() => _sortOption = v),
                        ),
                        const SizedBox(width: 8),
                        _buildSortButton(
                          'Bei: Juu ↘',
                          'price_desc',
                          _sortOption,
                          isDark,
                          primaryColor,
                          (v) => setStateModal(() => _sortOption = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Tumia Vichujio',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortButton(
    String label,
    String value,
    String currentVal,
    bool isDark,
    Color primaryColor,
    Function(String) onSelect,
  ) {
    final isSelected = currentVal == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final pages = [
      _buildHomeExploreTab(
        isDark,
        primaryColor,
        bgColor,
        cardBg,
        textColor,
        subtextColor,
      ),
      _buildDiscoverPropertiesTab(
        isDark,
        primaryColor,
        bgColor,
        cardBg,
        textColor,
        subtextColor,
      ),
      const CustomMapPage(),
      const VideoFeedPage(),
      _buildAccountTab(
        isDark,
        primaryColor,
        bgColor,
        cardBg,
        textColor,
        subtextColor,
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF282828) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: cardBg,
          selectedItemColor: primaryColor,
          unselectedItemColor: subtextColor,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Nyumbani',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.saved_search_rounded),
              label: 'Gundua',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Ramani',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle_filled),
              label: 'Video Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Akaunti',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeExploreTab(
    bool isDark,
    Color primaryColor,
    Color bgColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    final authProvider = Provider.of<AuthProvider>(context);

    return CustomScrollView(
      slivers: [
        // Top Brand Header
        SliverAppBar(
          floating: true,
          pinned: false,
          backgroundColor: cardBg,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, const Color(0xFF1B5E20)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/seriki.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERIK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    authProvider.isLoggedIn
                        ? 'Habari, ${authProvider.userName ?? "Mpangaji"}'
                        : 'Pata Makazi Yako Salama',
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Video Feed Shortcut
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              tooltip: 'Tazama Video za Nyumba',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VideoFeedPage(isVisible: true),
                  ),
                );
              },
            ),
            // Notifications Icon
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications_outlined, color: textColor),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),

        // Search Bar & Filter Strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Search Input
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search_rounded, color: primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText: 'Tafuta chuo, eneo, mkoa au aina...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: subtextColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: _isListening
                              ? const Color(0xFFEF4444)
                              : primaryColor,
                        ),
                        onPressed: _isListening
                            ? _stopListening
                            : _startListening,
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          onPressed: () =>
                              _showFilterModal(isDark, primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // University quick filter chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: universities.length + 1,
                    itemBuilder: (context, index) {
                      final name = index == 0
                          ? 'Zote'
                          : universities[index - 1]['name'] as String;
                      final isSelected = _selectedUniversity == name;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUniversity = name;
                            _applyFilters();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                      ? const Color(0xFF222222)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                        ? const Color(0xFF333333)
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name == 'Zote' ? '🏛️ Vyuo Zote' : '🎓 $name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Category Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryPill(
                        'Zote',
                        'all',
                        Icons.dashboard_rounded,
                        isDark,
                        primaryColor,
                      ),
                      _buildCategoryPill(
                        'Apartments',
                        'apartments',
                        Icons.apartment_rounded,
                        isDark,
                        primaryColor,
                      ),
                      _buildCategoryPill(
                        'Karibu na Chuo',
                        'campus',
                        Icons.school_rounded,
                        isDark,
                        primaryColor,
                      ),
                      _buildCategoryPill(
                        'Video Tours',
                        'videos',
                        Icons.videocam_rounded,
                        isDark,
                        primaryColor,
                      ),
                      _buildCategoryPill(
                        'Bei Nafuu (≤250k)',
                        'budget',
                        Icons.savings_rounded,
                        isDark,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured Verified Rentals Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nyumba Zilizohakikiwa (Verified)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_filteredSpots.length} zipo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured Horizontal Carousel
        if (_filteredSpots.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 270,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredSpots.take(6).length,
                itemBuilder: (context, index) {
                  final spot = _filteredSpots[index];
                  return _buildFeaturedCard(
                    spot,
                    isDark,
                    primaryColor,
                    cardBg,
                    textColor,
                    subtextColor,
                  );
                },
              ),
            ),
          ),

        // Popular Campus Hubs Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vyuo Vikuu Maarufu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('Tazama Zote'),
                ),
              ],
            ),
          ),
        ),

        // Campus Cards Carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: universities.length,
              itemBuilder: (context, index) {
                final uni = universities[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UniversityDetailPage(university: uni),
                      ),
                    );
                  },
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.06,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: uni['image'],
                            fit: BoxFit.cover,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    uni['city'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  uni['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${uni['houses']} Nyumba zinapatikana',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // All Available Houses List
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nyumba Zote za Kupanga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: primaryColor,
                  ),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
              ],
            ),
          ),
        ),

        // Rental Spot Grid/List
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_filteredSpots.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 54,
                      color: subtextColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'Hakuna nyumba zilizopatikana',
                        en: 'No houses found',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jaribu kubadili maneno au chagua chuo kingine.',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final spot = _filteredSpots[index];
                return _buildVerticalHouseCard(
                  spot,
                  isDark,
                  primaryColor,
                  cardBg,
                  textColor,
                  subtextColor,
                );
              }, childCount: _filteredSpots.length),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryPill(
    String label,
    String categoryKey,
    IconData icon,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = _selectedCategory == categoryKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryKey;
          _applyFilters();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF222222) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    return GestureDetector(
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RentalDetailScreen(spot: spot)),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: spot.hasImages()
                      ? CachedNetworkImage(
                          imageUrl: spot.images.first,
                          height: 145,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 145,
                          color: primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.home_rounded,
                            size: 48,
                            color: primaryColor,
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      spot.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: SavedHouseButton(houseId: spot.id),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.brandName.isNotEmpty
                        ? spot.brandName
                        : 'Nyumba ya Kisasa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: subtextColor,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          spot.street.isNotEmpty
                              ? '${spot.street}, ${spot.district}'
                              : spot.district,
                          style: TextStyle(fontSize: 11, color: subtextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        spot.formattedPrice,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.bed_outlined,
                            size: 14,
                            color: subtextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${spot.bedrooms}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalHouseCard(
    RentalSpot spot,
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          if (!authProvider.isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RentalDetailScreen(spot: spot)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: spot.hasImages()
                    ? CachedNetworkImage(
                        imageUrl: spot.images.first,
                        width: 105,
                        height: 105,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 105,
                        height: 105,
                        color: primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.home_rounded,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            spot.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SavedHouseButton(houseId: spot.id),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spot.brandName.isNotEmpty
                          ? spot.brandName
                          : 'Nyumba ya Kupanga',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${spot.street.isNotEmpty ? "${spot.street}, " : ""}${spot.district}',
                      style: TextStyle(fontSize: 11, color: subtextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          spot.formattedPrice,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.bed_outlined,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${spot.bedrooms} Vyumba',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subtextColor,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildDiscoverPropertiesTab(
    bool isDark,
    Color primaryColor,
    Color bgColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Gundua Nyumba (Properties)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterModal(isDark, primaryColor),
          ),
        ],
      ),
      body: _filteredSpots.isEmpty
          ? Center(
              child: Text(
                context.tr(
                  'Hakuna nyumba zilizopatikana.',
                  en: 'No houses found.',
                ),
                style: TextStyle(color: subtextColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSpots.length,
              itemBuilder: (context, index) {
                final spot = _filteredSpots[index];
                return _buildVerticalHouseCard(
                  spot,
                  isDark,
                  primaryColor,
                  cardBg,
                  textColor,
                  subtextColor,
                );
              },
            ),
    );
  }

  Widget _buildAccountTab(
    bool isDark,
    Color primaryColor,
    Color bgColor,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Akaunti & Mipangilio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: Text(
                      (authProvider.userName?.isNotEmpty == true
                              ? authProvider.userName![0]
                              : 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userName ?? 'Mgeni (Guest)',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.userEmail ?? 'Hujaingia kwenye mfumo',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authProvider.isLoggedIn
                                ? (authProvider.isLandlord
                                      ? 'Mwenye Nyumba (Landlord)'
                                      : 'Mpangaji (Tenant)')
                                : 'Akaunti ya Mgeni',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (authProvider.isLoggedIn) ...[
              _buildSettingTile(
                icon: Icons.edit_outlined,
                title: 'Hariri Profaili',
                subtitle: 'Badilisha jina na namba ya simu',
                color: const Color(0xFF0EA5E9),
                isDark: isDark,
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditPage(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.settings_outlined,
                title: 'Mipangilio',
                subtitle: 'Privacy, Terms, About na taarifa za app',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppSettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],

            // If not logged in, show Login / Register prompt
            if (!authProvider.isLoggedIn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingia Kwenye Akaunti Yako',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kufuatilia maombi, mikataba na malipo ya kodi.',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text('Ingia'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Landlord Switch (if landlord or wants to register house)
            if (authProvider.isLandlord)
              _buildSettingTile(
                icon: Icons.dashboard_customize_rounded,
                title: 'Dashboard ya Mwenye Nyumba',
                subtitle: 'Simamia nyumba, wapangaji na mapato yako',
                color: const Color(0xFF0EA5E9),
                isDark: isDark,
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RentalHomePage()),
                  );
                },
              ),

            // Notification / Smart Alerts
            _buildSettingTile(
              icon: Icons.notifications_active_rounded,
              title: 'Arifa & Smart Alerts',
              subtitle: 'Taarifa za nyumba mpya na maombi',
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              cardBg: cardBg,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),

            // Theme Switcher
            _buildSettingTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: 'Muonekano wa App (Theme)',
              subtitle: isDark ? 'Muonekano wa Giza' : 'Muonekano wa Mwanga',
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              cardBg: cardBg,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () => themeProvider.toggleTheme(),
            ),

            // Language Switcher
            _buildSettingTile(
              icon: Icons.translate_rounded,
              title: 'Lugha (Language)',
              subtitle: themeProvider.languageCode == 'sw'
                  ? 'Kiswahili (Tanzania)'
                  : 'English',
              color: const Color(0xFF10B981),
              isDark: isDark,
              cardBg: cardBg,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () => themeProvider.toggleLanguage(),
            ),

            // Logout
            if (authProvider.isLoggedIn)
              _buildSettingTile(
                icon: Icons.logout_rounded,
                title: 'Toka Kwenye Akaunti (Sign Out)',
                subtitle: 'Funga session kwenye kifaa hiki',
                color: const Color(0xFFEF4444),
                isDark: isDark,
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () async {
                  await ApiService.logout();
                  if (!context.mounted) return;
                  authProvider.logout();
                  setState(() => _currentIndex = 0);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: subtextColor),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: subtextColor,
          size: 20,
        ),
      ),
    );
  }
}
