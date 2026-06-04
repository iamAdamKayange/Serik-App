import 'package:flutter/material.dart';
import 'package:serkapp/pages/custom_map_page.dart';
import 'package:serkapp/pages/login_page.dart';
import 'package:serkapp/pages/university_detail_page.dart';
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
    // ... (keep your existing universities list - same as before)
    {
      "name": "UDOM",
      "shortName": "UDOM",
      "lat": -6.21630,
      "lng": 35.7419,
      "radius_km": 1.5,
      "desc": "Pata nyumba za kisasa karibu na Chuo Kikuu cha Dodoma",
      "image":
          "https://images.unsplash.com/photo-1562774053-701939374585?w=300&h=160&fit=crop",
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
      "image":
          "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=300&h=160&fit=crop",
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
      "image":
          "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=300&h=160&fit=crop",
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
      "image":
          "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=300&h=160&fit=crop",
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
      "image":
          "https://images.unsplash.com/photo-1562774053-701939374585?w=300&h=160&fit=crop",
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
      "image":
          "https://images.unsplash.com/photo-1516455590571-18256e4bb9ff?w=300&h=160&fit=crop",
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
      "image":
          "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=300&h=160&fit=crop",
      "houses": 25,
      "rating": 4.4,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUniversities = [];
  bool _isSearching = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedFilter = 'Zote';
  late AnimationController _animationController;
  // ignore: unused_field
  late Animation<double> _fadeAnimation;

  int _currentIndex = 0;
  late List<Widget>
  _pages; // Don't initialize here with context-dependent widgets

  @override
  void initState() {
    super.initState();
    _filteredUniversities = List.from(universities);
    _initializeSpeech();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Don't initialize _pages here with context-dependent widgets
    _pages = [Container(), const CustomMapPage(), const LoginPage()];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the home page content here, after context is ready
    _pages[0] = _buildHomeContent();
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

  void _filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUniversities = List.from(universities);
        _isSearching = false;
      });
      return;
    }
    List<Map<String, dynamic>> filteredList = universities.where((uni) {
      return uni['name'].toLowerCase().contains(query.toLowerCase()) ||
          uni['desc'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredUniversities = filteredList;
      _isSearching = true;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredUniversities = List.from(universities);
      _isSearching = false;
    });
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
    final isDarkMode = themeProvider.isDarkMode;

    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    Color backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    Color subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)]
                      : [primaryColor.withOpacity(0.05), Colors.white],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 50),
                          Column(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'S',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Serik',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => themeProvider.toggleTheme(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            'Geto lako',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'kikanjani pako',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _isSearching
                          ? primaryColor
                          : (isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[200]!),
                      width: 1.5,
                    ),
                    boxShadow: _isSearching
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Tafuta chuo kikuu au eneo...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
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
                          Container(
                            width: 1,
                            height: 24,
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[300],
                          ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: _isListening ? Colors.red : primaryColor,
                              size: 20,
                            ),
                            onPressed: _isListening
                                ? _stopListening
                                : _startListening,
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: _filterSearchResults,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Zote', 'Karibu', 'Nafuu', 'Kisasa', 'Salama']
                        .map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) =>
                                  setState(() => _selectedFilter = filter),
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : subtextColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vyuo Vikuu Maarufu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (_isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_filteredUniversities.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_filteredUniversities.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 60,
                    color: subtextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hakuna matokeo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Jaribu kutumia maneno mengine',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUniversityCard(
                _filteredUniversities[index],
                index,
                isDarkMode,
                primaryColor,
                surfaceColor,
                textColor,
                subtextColor,
              ),
              childCount: _filteredUniversities.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
                child: Image.network(
                  university['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: primaryColor.withOpacity(0.1),
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
                              color: Colors.amber.withOpacity(0.15),
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
                            '${university['houses']} nyumba',
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    Color primaryColor = isDarkMode
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
    Color surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Nyumbani',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Ramani',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Akaunti',
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
