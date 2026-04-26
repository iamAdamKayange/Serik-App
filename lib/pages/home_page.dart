// Mabadiliko: Nimeongeza lat, lng, radius_km kwa kila chuo
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:serkapp/pages/custom_map_page.dart';
import 'package:serkapp/pages/login_page.dart';
import 'package:serkapp/pages/university_detail_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePage extends StatefulWidget {
  final Function()? onHouseAdded;
  const HomePage({super.key, this.onHouseAdded});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mabadiliko: Nimeongeza lat, lng, radius_km kwa kila chuo
  final List<Map<String, dynamic>> universities = [
    {
      'name': 'UDOM',
      'lat': -6.21630,
      'lng': 35.7419,
      'radius_km': 1.5,
      'desc': 'Karibu kwa nyumba za kupanga karibu na UDOM',
      'image': 'https://picsum.photos/200/120?random=1',
      'progress': 0.25,
      'houses': 45,
      'rating': 4.2,
    },
    {
      'name': 'UDSM',
      'lat': -6.7816,
      'lng': 39.20567,
      'radius_km': 2.0,
      'desc': 'Karibu kwa nyumba za kupanga karibu na UDSM',
      'image': 'https://picsum.photos/200/120?random=2',
      'progress': 0.20,
      'houses': 38,
      'rating': 4.5,
    },
    {
      'name': 'MUST',
      'lat': -8.909401,
      'lng': 33.460773,
      'radius_km': 1.0,
      'desc': 'Karibu kwa nyumba za kupanga karibu na MUST',
      'image': 'https://picsum.photos/200/120?random=3',
      'progress': 0.10,
      'houses': 22,
      'rating': 4.0,
    },
    {
      'name': 'DIT',
      'lat': -6.8144,
      'lng': 39.2833,
      'radius_km': 1.2,
      'desc': 'Karibu kwa nyumba za kupanga karibu na DIT',
      'image': 'https://picsum.photos/200/120?random=4',
      'progress': 0.15,
      'houses': 28,
      'rating': 3.8,
    },
    {
      'name': 'MUCE',
      'lat': -7.75962,
      'lng': 35.68888,
      'radius_km': 1.8,
      'desc': 'Karibu kwa nyumba za kupanga karibu na MUCE',
      'image': 'https://picsum.photos/200/120?random=5',
      'progress': 0.18,
      'houses': 32,
      'rating': 4.1,
    },
    {
      'name': 'IFM',
      'lat': -6.81395,
      'lng': 39.29366,
      'radius_km': 1.3,
      'desc': 'Karibu kwa nyumba za kupanga karibu na IFM',
      'image': 'https://picsum.photos/200/120?random=6',
      'progress': 0.12,
      'houses': 25,
      'rating': 3.9,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUniversities = [];
  bool _isSearching = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  String _selectedFilter = 'Zote';

  @override
  void initState() {
    super.initState();
    _filteredUniversities = List.from(universities);
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    if (!available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Voice recognition haipatikani")));
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

  Color _getProgressColor(double progress) {
    if (progress >= 0.7) return Colors.green;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildUniversityCard(Map<String, dynamic> university, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(university['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 12),
                              SizedBox(width: 4),
                              Text(
                                university['rating'].toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          university['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          university['desc'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              size: 14,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${university['houses']} Nyumba',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${(university['progress'] * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            LinearPercentIndicator(
                              percent: university['progress'],
                              lineHeight: 6,
                              backgroundColor: Colors.grey[300]!,
                              progressColor: _getProgressColor(
                                university['progress'],
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
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _navigateToUniversityDetails(university),
              mini: true,
              backgroundColor: Colors.blue,
              child: Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomMapPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Ramani",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                          },
                          child: Text(
                            "Mwenye nyumba",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Serik",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Tafuta chuo kikuu au eneo...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: _clearSearch,
                              ),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey[300],
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic_off : Icons.mic,
                                color: _isListening ? Colors.red : Colors.blue,
                              ),
                              onPressed: () {
                                _isListening
                                    ? _stopListening()
                                    : _startListening();
                              },
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                      ),
                      onChanged: _filterSearchResults,
                    ),
                    SizedBox(height: 20),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            ['Zote', 'Maarufu', 'Karibu', 'Nafuhu', 'Kitonga']
                                .map(
                                  (filter) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(filter),
                                      selected: _selectedFilter == filter,
                                      onSelected: (selected) {
                                        setState(
                                          () => _selectedFilter = filter,
                                        );
                                      },
                                      backgroundColor: Colors.grey[200],
                                      selectedColor: Colors.blue,
                                      labelStyle: TextStyle(
                                        color: _selectedFilter == filter
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Vyuo Vikuu",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (_isSearching)
                      Text(
                        "${_filteredUniversities.length} matokeo",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ),
            _filteredUniversities.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Hakuna matokeo",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Badilisha maneno ya utafutaji au tafuta kwa sauti",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _buildUniversityCard(
                          _filteredUniversities[index],
                          index,
                        ),
                      ),
                      childCount: _filteredUniversities.length,
                    ),
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
    super.dispose();
  }
}
