import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:serkapp/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serkapp/providers/auth_provider.dart';
import 'package:serkapp/providers/theme_provider.dart';
import 'package:serkapp/pages/custom_map_page.dart';
import 'package:serkapp/model/rental_model.dart';
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/screen/rental_detail_screen.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:url_launcher/url_launcher.dart';

class NormalUserHomepage extends StatefulWidget {
  const NormalUserHomepage({super.key});

  @override
  State<NormalUserHomepage> createState() => _NormalUserHomepageState();
}

class _NormalUserHomepageState extends State<NormalUserHomepage> {
  List<RentalSpot> _recentHouses = [];
  List<RentalSpot> _allHouses = [];
  List<RentalSpot> _filteredHouses = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Home, 1: Profile, 2: Favorites

  // Favorites
  Set<String> _favoriteIds = {};
  List<RentalSpot> _favoriteHouses = [];

  // Filter & Sort
  int? _filterBedrooms;
  double? _minPrice;
  double? _maxPrice;
  String _sortOption = 'default'; // default, price_asc, price_desc

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFavorites();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> housesJson = await ApiService.getAllHouses();
      final List<RentalSpot> spots = housesJson.map((json) {
        final houseData = HouseData.fromJson(json as Map<String, dynamic>);
        return RentalSpot.fromHouseData(houseData);
      }).toList();
      setState(() {
        _allHouses = spots;
        _recentHouses = spots.take(6).toList();
        _applyFilterAndSort();
        _isLoading = false;
      });
      _updateFavoritesList();
    } catch (e) {
      debugPrint('Error loading houses: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== FAVORITES ====================
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favoriteIds = favorites.toSet();
    });
    _updateFavoritesList();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.toList());
  }

  void _toggleFavorite(RentalSpot spot) {
    setState(() {
      if (_favoriteIds.contains(spot.id)) {
        _favoriteIds.remove(spot.id);
      } else {
        _favoriteIds.add(spot.id);
      }
    });
    _saveFavorites();
    _updateFavoritesList();
  }

  void _updateFavoritesList() {
    setState(() {
      _favoriteHouses = _allHouses
          .where((spot) => _favoriteIds.contains(spot.id))
          .toList();
    });
  }

  bool _isFavorite(RentalSpot spot) => _favoriteIds.contains(spot.id);

  // ==================== FILTER & SORT ====================
  void _applyFilterAndSort() {
    List<RentalSpot> filtered = List.from(_allHouses);

    if (_filterBedrooms != null) {
      filtered = filtered
          .where((spot) => spot.bedrooms == _filterBedrooms)
          .toList();
    }

    if (_minPrice != null) {
      filtered = filtered
          .where((spot) => spot.rentPrice >= _minPrice!)
          .toList();
    }
    if (_maxPrice != null) {
      filtered = filtered
          .where((spot) => spot.rentPrice <= _maxPrice!)
          .toList();
    }

    if (_sortOption == 'price_asc') {
      filtered.sort((a, b) => a.rentPrice.compareTo(b.rentPrice));
    } else if (_sortOption == 'price_desc') {
      filtered.sort((a, b) => b.rentPrice.compareTo(a.rentPrice));
    }

    setState(() {
      _filteredHouses = filtered;
      _recentHouses = _allHouses.take(6).toList();
    });
  }

  void _showFilterSortSheet() {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chuja na Panga',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Idadi ya Vyumba',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        'Zote',
                        _filterBedrooms == null,
                        () => setStateSheet(() => _filterBedrooms = null),
                        isDarkMode,
                      ),
                      _buildFilterChip(
                        '1',
                        _filterBedrooms == 1,
                        () => setStateSheet(() => _filterBedrooms = 1),
                        isDarkMode,
                      ),
                      _buildFilterChip(
                        '2',
                        _filterBedrooms == 2,
                        () => setStateSheet(() => _filterBedrooms = 2),
                        isDarkMode,
                      ),
                      _buildFilterChip(
                        '3',
                        _filterBedrooms == 3,
                        () => setStateSheet(() => _filterBedrooms = 3),
                        isDarkMode,
                      ),
                      _buildFilterChip(
                        '4+',
                        _filterBedrooms == 4,
                        () => setStateSheet(() => _filterBedrooms = 4),
                        isDarkMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bei (TZS)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: context.tr('Kuanzia', en: 'From'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _minPrice = val.isEmpty
                                ? null
                                : double.tryParse(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: context.tr('Mpaka', en: 'To'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _maxPrice = val.isEmpty
                                ? null
                                : double.tryParse(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Panga kwa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSortChip(
                        'Chaguo msingi',
                        _sortOption == 'default',
                        () => setStateSheet(() => _sortOption = 'default'),
                        isDarkMode,
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(
                        'Bei: Chini hadi Juu',
                        _sortOption == 'price_asc',
                        () => setStateSheet(() => _sortOption = 'price_asc'),
                        isDarkMode,
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(
                        'Bei: Juu hadi Chini',
                        _sortOption == 'price_desc',
                        () => setStateSheet(() => _sortOption = 'price_desc'),
                        isDarkMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setStateSheet(() {
                              _filterBedrooms = null;
                              _minPrice = null;
                              _maxPrice = null;
                              _sortOption = 'default';
                            });
                            _applyFilterAndSort();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey),
                          ),
                          child: Text(context.tr('Weka Upya', en: 'Reset')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilterAndSort();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: Text(context.tr('Tumia', en: 'Apply')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : (isDarkMode ? Colors.white70 : Colors.black87),
      ),
    );
  }

  Widget _buildSortChip(
    String label,
    bool selected,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : (isDarkMode ? Colors.white70 : Colors.black87),
      ),
    );
  }

  // ==================== SHARE ====================
  Future<void> _shareHouse(RentalSpot spot) async {
    final String message =
        'Angalia nyumba hii: ${spot.brandName}\n'
        'Namba ya Nyumba: ${spot.houseNumber}\n'
        'Bei: ${spot.formattedPrice}\n'
        'Eneo: ${spot.getShortAddress()}';
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Taarifa ya nyumba imenakiliwa!', en: 'House information copied!'))),
    );
  }

  // ==================== CALL LANDLORD ====================
  Future<void> _callLandlord(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Namba ya simu haipatikani', en: 'Phone number is unavailable'))),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Haiwezi kupiga simu', en: 'Could not make a call'))));
    }
  }

  // ==================== LOGOUT ====================
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await ApiService.logout();
    authProvider.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  void _showLogoutDialog() {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Toka Akaunti?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Una hakika unataka kutoka kwenye akaunti yako?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Ghairi', en: 'Cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.tr('Toka', en: 'Logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomeFeed(isDarkMode, themeProvider),
          _buildProfileTab(isDarkMode),
          _buildFavoritesTab(isDarkMode),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDarkMode),
    );
  }

  Widget _buildBottomNavigationBar(bool isDarkMode) {
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Nyumbani',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Akaunti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Zinazopendwa',
          ),
        ],
      ),
    );
  }

  // ==================== HOME FEED ====================
  Widget _buildHomeFeed(bool isDarkMode, ThemeProvider themeProvider) {
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    final gradientColors = isDarkMode
        ? [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)]
        : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Habari, ${authProvider.userName?.split(' ').first ?? 'Mwananchi'}!',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tafuta nyumba bora karibu nawe',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: Colors.white,
                                ),
                                onPressed: () => themeProvider.toggleTheme(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomMapPage(),
                            ),
                          ),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.search_rounded,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[400],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Tafuta nyumba, eneo, au bei...',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    Icons.filter_list_rounded,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  onPressed: _showFilterSortSheet,
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomMapPage()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nyumba Mpya Zilizoongezwa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomMapPage()),
                    ),
                    child: Text(
                      'Tazama Zote',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recentHouses.length,
                      itemBuilder: (context, index) =>
                          _buildHorizontalHouseCard(
                            _recentHouses[index],
                            isDarkMode,
                            primaryColor,
                          ),
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inavyopendekezwa Kwako',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.sort_by_alpha, color: primaryColor),
                        onPressed: _showFilterSortSheet,
                        tooltip: context.tr('Chuja na Panga', en: 'Filter and Sort'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >=
                      (_filteredHouses.length > 4
                          ? 4
                          : _filteredHouses.length)) {
                    return const SizedBox.shrink();
                  }
                  return _buildVerticalHouseCard(
                    _filteredHouses[index],
                    isDarkMode,
                    primaryColor,
                  );
                },
                childCount: _filteredHouses.length > 4
                    ? 4
                    : _filteredHouses.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomMapPage()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Chunguza Nyumba Zote',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHorizontalHouseCard(
    RentalSpot spot,
    bool isDarkMode,
    Color primaryColor,
  ) {
    final thumbnail = spot.videoThumbnails.isNotEmpty
        ? spot.videoThumbnails.first
        : (spot.hasImages() ? spot.getFirstImage() : null);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: spot)),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.white : Colors.black).withValues(
                alpha: 0.05,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            height: 120,
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            height: 120,
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          height: 120,
                          color: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(
                            Icons.home_rounded,
                            size: 40,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                ),
                if (spot.videos.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      spot.formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(spot),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite(spot)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: _isFavorite(spot) ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                spot.brandName, // jina maarufu
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 10,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      spot.getShortAddress(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.green[900] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${spot.bedrooms} Vyumba',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDarkMode
                            ? Colors.green[300]
                            : Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      spot.type,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
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
    bool isDarkMode,
    Color primaryColor,
  ) {
    final thumbnail = spot.videoThumbnails.isNotEmpty
        ? spot.videoThumbnails.first
        : (spot.hasImages() ? spot.getFirstImage() : null);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RentalDetailScreen(spot: spot)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.white : Colors.black).withValues(
                alpha: 0.03,
              ),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: 100,
                            height: 100,
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 100,
                            height: 100,
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(
                            Icons.home_rounded,
                            size: 40,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spot.brandName, // jina maarufu
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite(spot)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite(spot) ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _toggleFavorite(spot),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.share,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () => _shareHouse(spot),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.phone,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () => _callLandlord(spot.phone),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            spot.getShortAddress(),
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
                    const SizedBox(height: 8),
                    Text(
                      spot.formattedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.green[900]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${spot.bedrooms} Vyumba',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: spot.status == 'Inapatikana'
                                ? (isDarkMode
                                      ? Colors.green[900]
                                      : Colors.green[50])
                                : (isDarkMode
                                      ? Colors.orange[900]
                                      : Colors.orange[50]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            spot.status,
                            style: TextStyle(
                              fontSize: 10,
                              color: spot.status == 'Inapatikana'
                                  ? (isDarkMode
                                        ? Colors.green[300]
                                        : Colors.green[700])
                                  : (isDarkMode
                                        ? Colors.orange[300]
                                        : Colors.orange[700]),
                            ),
                          ),
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
                color: isDarkMode ? Colors.grey[600] : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE TAB (NO DARK MODE TOGGLE) ====================
  Widget _buildProfileTab(bool isDarkMode) {
    final authProvider = Provider.of<AuthProvider>(context);
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.white : Colors.black).withValues(
                    alpha: 0.03,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.person, size: 50, color: primaryColor),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.userName ?? 'Mwananchi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.userEmail ?? 'email@example.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    authProvider.userRole == 'landlord'
                        ? 'Mwenye Nyumba'
                        : 'Mtafuta Nyumba',
                    style: TextStyle(fontSize: 12, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.white : Colors.black).withValues(
                    alpha: 0.03,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_work_outlined, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumla ya Nyumba',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      Text(
                        '${_allHouses.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            Icons.history_rounded,
            'Historia ya Utafutaji',
            'Nyumba ulizozitazama',
            () {},
            isDarkMode,
            primaryColor,
          ),
          _buildMenuItem(
            Icons.notifications_outlined,
            'Arifa',
            'Pata taarifa za nyumba mpya',
            () {},
            isDarkMode,
            primaryColor,
          ),
          _buildMenuItem(
            Icons.help_outline_rounded,
            'Msaada',
            'Maswali na majibu',
            () {},
            isDarkMode,
            primaryColor,
          ),
          _buildMenuItem(
            Icons.privacy_tip_outlined,
            'Sera ya Faragha',
            'Jinsi tunavyotumia data yako',
            () {},
            isDarkMode,
            primaryColor,
          ),
          const Divider(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout_rounded),
              label: Text(context.tr('Toka Akaunti', en: 'Logout')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== FAVORITES TAB ====================
  Widget _buildFavoritesTab(bool isDarkMode) {
    final primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(context.tr('Nyumba Unazozipenda', en: 'Favorite Houses')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _favoriteHouses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Hujapenda nyumba yoyote',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bonyeza icon ya heart kwenye nyumba unayopenda',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteHouses.length,
              itemBuilder: (context, index) => _buildVerticalHouseCard(
                _favoriteHouses[index],
                isDarkMode,
                primaryColor,
              ),
            ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDarkMode,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDarkMode ? Colors.grey[600] : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}


