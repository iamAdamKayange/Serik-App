import 'package:flutter/material.dart';
import 'dart:math';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/model/rental_model.dart';
import 'package:serkapp/pages/custom_map_page.dart';
import 'package:serkapp/pages/login_page.dart';
import 'package:serkapp/pages/notification_screen.dart';
import 'package:serkapp/pages/register_page.dart';
import 'package:serkapp/pages/rental_home_page.dart';
import 'package:serkapp/pages/university_detail_page.dart';
import 'package:serkapp/pages/video_feed_page.dart';
import 'package:serkapp/providers/auth_provider.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
      "radius_km": 1.5,
      "desc": "Pata nyumba za kisasa karibu na Chuo Kikuu cha Dodoma",
      "image": "assets/images/udom.jpg",
      "houses": 45,
      "rating": 4.8,
    },
    {
      "name": "UDSM",
      "shortName": "UDSM",
      "lat": -6.7816,
      "lng": 39.20567,
      "radius_km": 2.0,
      "desc": "Nyumba bora karibu na Chuo Kikuu cha Dar es Salaam",
      "image": "assets/images/udsm.jpg",
      "houses": 38,
      "rating": 4.9,
    },
    {
      "name": "MUST",
      "shortName": "MUST",
      "lat": -8.909401,
      "lng": 33.460773,
      "radius_km": 1.0,
      "desc": "Makazi nafuu karibu na Mbeya University",
      "image": "assets/images/must.jpg",
      "houses": 22,
      "rating": 4.6,
    },
    {
      "name": "DIT",
      "shortName": "DIT",
      "lat": -6.8144,
      "lng": 39.2833,
      "radius_km": 1.2,
      "desc": "Nyumba za wanafunzi karibu na DIT",
      "image": "assets/images/dit.jpg",
      "houses": 28,
      "rating": 4.5,
    },
    {
      "name": "CBE",
      "shortName": "CBE",
      "lat": -6.1736,
      "lng": 35.7410,
      "radius_km": 1.5,
      "desc": "Pata nyumba za kisasa karibu na CBE Dodoma",
      "image": "assets/images/cbe.jpg",
      "houses": 30,
      "rating": 4.7,
    },
    {
      "name": "SUA",
      "shortName": "SUA",
      "lat": -6.6999,
      "lng": 36.6936,
      "radius_km": 1.8,
      "desc": "Nyumba za kupanga karibu na SUA Morogoro",
      "image": "assets/images/sua.jpg",
      "houses": 32,
      "rating": 4.7,
    },
    {
      "name": "IFM",
      "shortName": "IFM",
      "lat": -6.81395,
      "lng": 39.29366,
      "radius_km": 1.3,
      "desc": "Makazi bora karibu na IFM",
      "image": "assets/images/ifm.jpg",
      "houses": 25,
      "rating": 4.4,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUniversities = [];
  List<RentalSpot> _allRentalSpots = [];
  bool _isSearching = false;
  bool _isLoadingHouseCounts = true;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedFilter = 'all';
  late AnimationController _animationController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredUniversities = List.from(universities);
    _initializeSpeech();
    _loadUniversityHouseCounts();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      debugPrint("Speech recognition not available");
    }
  }

  void _startListening() {
    if (_isListening) return;
    _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _filterSearchResults(result.recognizedWords);
        });
      },
    );
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
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

  List<RentalSpot> _nearbySpotsForUniversity(Map<String, dynamic> university) {
    return _allRentalSpots
        .where((spot) => _isNearUniversity(spot, university))
        .toList();
  }

  bool _matchesSelectedFilter(Map<String, dynamic> university) {
    if (_selectedFilter == 'all') return true;
    final nearby = _nearbySpotsForUniversity(university);
    if (nearby.isEmpty) return false;

    switch (_selectedFilter) {
      case 'nearby':
        return nearby.any((spot) {
          final distance = _calculateDistance(
            (university['lat'] as num).toDouble(),
            (university['lng'] as num).toDouble(),
            spot.latitude,
            spot.longitude,
          );
          return distance <= 1.0;
        });
      case 'affordable':
        return nearby.any((spot) => spot.rentPrice <= 200000);
      case 'modern':
        return nearby.any(
          (spot) =>
              spot.hasTiles ||
              spot.hasCeiling ||
              spot.internetIncluded ||
              spot.layoutType != HouseLayoutType.shared,
        );
      case 'safe':
        return nearby.any((spot) => spot.hasFence);
      default:
        return true;
    }
  }

  Future<void> _loadUniversityHouseCounts() async {
    try {
      final housesJson = await ApiService.getAllHouses();
      final spots = housesJson
          .map((json) {
            final houseData = HouseData.fromJson(json as Map<String, dynamic>);
            return RentalSpot.fromHouseData(houseData);
          })
          .where((spot) => spot.hasValidLocation())
          .toList();

      if (!mounted) return;
      setState(() {
        _allRentalSpots = spots;
        for (final university in universities) {
          university['houses'] = _nearbySpotsForUniversity(university).length;
        }
        _isLoadingHouseCounts = false;
      });
      _applyUniversityFilters();
    } catch (e) {
      debugPrint('Error loading university house counts: $e');
      if (!mounted) return;
      setState(() => _isLoadingHouseCounts = false);
    }
  }

  void _applyUniversityFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final filteredList = universities.where((uni) {
      final matchesSearch =
          query.isEmpty ||
          uni['name'].toString().toLowerCase().contains(query) ||
          uni['shortName'].toString().toLowerCase().contains(query) ||
          uni['desc'].toString().toLowerCase().contains(query);
      return matchesSearch && _matchesSelectedFilter(uni);
    }).toList();

    filteredList.sort((a, b) {
      final houseCompare = (b['houses'] as int).compareTo(a['houses'] as int);
      if (houseCompare != 0) return houseCompare;
      return a['name'].toString().compareTo(b['name'].toString());
    });

    setState(() {
      _filteredUniversities = filteredList;
      _isSearching = query.isNotEmpty || _selectedFilter != 'all';
    });
  }

  void _filterSearchResults(String query) {
    _applyUniversityFilters();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
    _applyUniversityFilters();
  }

  void _navigateToUniversityDetails(Map<String, dynamic> university) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversityDetailPage(university: university),
      ),
    );
  }

  Widget _buildHomeContent() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = themeProvider.isDarkMode;

    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF7FAF7);
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final totalNearbyHouses = universities.fold<int>(
      0,
      (total, university) => total + ((university['houses'] as int?) ?? 0),
    );
    final firstName = authProvider.userName?.split(' ').first ?? '';
    final greeting = authProvider.isLoggedIn && firstName.isNotEmpty
        ? l10n.welcomeUser(firstName)
        : l10n.welcomeSerik;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: backgroundColor,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              14,
            ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.72),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.24),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authProvider.isLoggedIn
                                  ? l10n.userSubtitle
                                  : l10n.guestSubtitle,
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => themeProvider.toggleTheme(),
                        icon: Icon(
                          isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        color: primaryColor,
                        tooltip: l10n.switchTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.06)
                            : primaryColor.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDarkMode ? 0.28 : 0.07,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.heroBadge,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.heroTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.heroSubtitle,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _buildHeroStat(
                              '$totalNearbyHouses',
                              l10n.nearbyHouses,
                              primaryColor,
                              isDarkMode,
                            ),
                            const SizedBox(width: 10),
                            _buildHeroStat(
                              '${universities.length}',
                              l10n.universities,
                              primaryColor,
                              isDarkMode,
                            ),
                            const SizedBox(width: 10),
                            _buildHeroStat(
                              _isLoadingHouseCounts ? '...' : 'Live',
                              l10n.liveData,
                              primaryColor,
                              isDarkMode,
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
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchHeaderDelegate(
            minExtentValue: 86,
            maxExtentValue: 86,
            child: Container(
              color: backgroundColor,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: _buildSearchField(
                isDarkMode,
                primaryColor,
                surfaceColor,
                textColor,
                subtextColor,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActions(primaryColor, surfaceColor, isDarkMode),
                const SizedBox(height: 18),
                _buildFilterChips(isDarkMode, primaryColor, subtextColor),
                const SizedBox(height: 18),
                _buildSectionTitle(
                  l10n.popularUniversities,
                  _isLoadingHouseCounts
                      ? l10n.countingHomes
                      : l10n.results(_filteredUniversities.length),
                  textColor,
                  subtextColor,
                ),
              ],
            ),
          ),
        ),
        if (_filteredUniversities.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              color: backgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 62,
                      color: subtextColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noResults,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.tryAnotherFilter,
                      style: TextStyle(fontSize: 13, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 360 + (index * 55)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 22 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _buildUniversityCard(
                  _filteredUniversities[index],
                  index,
                  isDarkMode,
                  primaryColor,
                  surfaceColor,
                  textColor,
                  subtextColor,
                ),
              ),
              childCount: _filteredUniversities.length,
            ),
          ),
        SliverToBoxAdapter(
          child: Container(height: 96, color: backgroundColor),
        ),
      ],
    );
  }

  Widget _buildSearchField(
    bool isDarkMode,
    Color primaryColor,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSearching
              ? primaryColor.withValues(alpha: 0.55)
              : (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: TextStyle(fontSize: 14, color: subtextColor),
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: subtextColor,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                ),
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isListening ? Colors.red : primaryColor,
                  size: 21,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
        ),
        onChanged: _filterSearchResults,
      ),
    );
  }

  Widget _buildHeroStat(
    String value,
    String label,
    Color primaryColor,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    Color primaryColor,
    Color surfaceColor,
    bool isDarkMode,
  ) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _quickAction(
          Icons.play_circle_outline_rounded,
          l10n.openVideos,
          primaryColor,
          surfaceColor,
          isDarkMode,
          () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(width: 10),
        _quickAction(
          Icons.map_rounded,
          l10n.openMap,
          Colors.blue,
          surfaceColor,
          isDarkMode,
          () => setState(() => _currentIndex = 2),
        ),
        const SizedBox(width: 10),
        _quickAction(
          Icons.person_rounded,
          l10n.openAccount,
          Colors.deepPurple,
          surfaceColor,
          isDarkMode,
          () => setState(() => _currentIndex = 3),
        ),
      ],
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    Color color,
    Color surfaceColor,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    bool isDarkMode,
    Color primaryColor,
    Color subtextColor,
  ) {
    final l10n = AppLocalizations.of(context);
    final filters = {
      'all': (l10n.all, Icons.grid_view_rounded),
      'nearby': (l10n.nearby, Icons.near_me_rounded),
      'affordable': (l10n.affordable, Icons.savings_rounded),
      'modern': (l10n.modern, Icons.apartment_rounded),
      'safe': (l10n.safe, Icons.verified_user_rounded),
    };

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters.keys.elementAt(index);
          final filterData = filters[filter]!;
          final isSelected = _selectedFilter == filter;
          return ChoiceChip(
            avatar: Icon(
              filterData.$2,
              size: 17,
              color: isSelected ? Colors.white : primaryColor,
            ),
            label: Text(filterData.$1),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedFilter = filter);
              _applyUniversityFilters();
            },
            selectedColor: primaryColor,
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : subtextColor,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isSelected
                    ? primaryColor
                    : (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String trailing,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
        Text(
          trailing,
          style: TextStyle(
            color: subtextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildUniversityCard(
    Map<String, dynamic> university,
    int index,
    bool isDarkMode,
    Color primaryColor,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
  ) {
    final l10n = AppLocalizations.of(context);
    // Determine if image is asset or network
    final String imagePath = university['image'];
    final bool isAsset = imagePath.startsWith('assets/');

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToUniversityDetails(university),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          color: primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.school_rounded,
                            size: 32,
                            color: primaryColor,
                          ),
                        ),
                      )
                    : Image.network(
                        imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          color: primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.school_rounded,
                            size: 32,
                            color: primaryColor,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              university['name'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 10,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  university['rating'].toString(),
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        university['desc'],
                        style: TextStyle(fontSize: 11, color: subtextColor),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 12,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isLoadingHouseCounts
                                ? l10n.countingHomes
                                : '${university['houses']} nyumba',
                            style: TextStyle(fontSize: 11, color: primaryColor),
                          ),
                          const SizedBox(width: 14),
                          Icon(
                            Icons.straighten_rounded,
                            size: 12,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${university['radius_km']} km',
                            style: TextStyle(fontSize: 11, color: primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountPage(
    bool isDarkMode,
    Color primaryColor,
    Color surfaceColor,
    Color subtextColor,
  ) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(l10n.account),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 42,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.unlockServices,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.hiddenDetailsNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subtextColor, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(l10n.signIn),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(l10n.register),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(l10n.account),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
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
                        authProvider.userName ?? 'User',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.userEmail ?? '',
                        style: TextStyle(color: subtextColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        authProvider.userRole ?? 'normal',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _accountActionTile(
            icon: Icons.search_rounded,
            title: l10n.continueSearching,
            subtitle: l10n.continueSearchingSubtitle,
            color: primaryColor,
            onTap: () => setState(() => _currentIndex = 0),
          ),
          _accountActionTile(
            icon: Icons.translate_rounded,
            title: l10n.language,
            subtitle: themeProvider.languageCode == 'sw'
                ? l10n.swahili
                : l10n.english,
            color: Colors.teal,
            onTap: () => themeProvider.toggleLanguage(),
          ),
          _accountActionTile(
            icon: themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: l10n.theme,
            subtitle: themeProvider.isDarkMode ? l10n.darkMode : l10n.lightMode,
            color: Colors.indigo,
            onTap: () => themeProvider.toggleTheme(),
          ),
          if (authProvider.isLandlord)
            _accountActionTile(
              icon: Icons.dashboard_customize_rounded,
              title: l10n.landlordDashboard,
              subtitle: l10n.landlordDashboardSubtitle,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RentalHomePage()),
              ),
            ),
          _accountActionTile(
            icon: Icons.logout_rounded,
            title: l10n.signOut,
            subtitle: l10n.signOutSubtitle,
            color: Colors.red,
            onTap: () async {
              await ApiService.logout();
              if (!mounted) return;
              Provider.of<AuthProvider>(context, listen: false).logout();
              setState(() => _currentIndex = 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _accountActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context);

    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final pages = [
      _buildHomeContent(),
      VideoFeedPage(isVisible: _currentIndex == 1),
      const CustomMapPage(),
      const NotificationScreen(),
      _buildAccountPage(isDarkMode, primaryColor, surfaceColor, subtextColor),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfaceColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: subtextColor,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: l10n.videos,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_rounded),
              label: l10n.map,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_rounded),
              label: l10n.tr('Arifa', en: 'Alerts'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.account,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    _animationController.dispose();
    super.dispose();
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  _SearchHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return minExtentValue != oldDelegate.minExtentValue ||
        maxExtentValue != oldDelegate.maxExtentValue ||
        child != oldDelegate.child;
  }
}
