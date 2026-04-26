import 'package:flutter/services.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:flutter/widgets.dart';
import '../models/location_model.dart';

class CsvLocationService {
  static final Map<String, List<LocationItem>> _allData = {};
  static final List<String> _regions = [];
  static bool _isLoaded = false;

  // Load all CSV files
  static Future<void> loadAllLocations() async {
    if (_isLoaded) return;

    // Orodha ya mikoa yote kutoka kwenye CSV files zako
    final List<String> regionFiles = [
      'arusha',
      'dar_es_salaam',
      'dodoma',
      'geita',
      'iringa',
      'kagera',
      'katavi',
      'kigoma',
      'kilimanjaro',
      'lindi',
      'manyara',
      'mara',
      'mbeya',
      'morogoro',
      'mtwara',
      'mwanza',
      'njombe',
      'pemba_kaskazini',
      'pemba_kusini',
      'pwani',
      'rukwa',
      'ruvuma',
      'shinyanga',
      'simiyu',
      'singida',
      'songwe',
      'tabora',
      'tanga',
      'unguja_kaskazini',
      'unguja_kusini',
      'unguja_mjini',
    ];

    for (String regionFile in regionFiles) {
      await _loadSingleCsv(regionFile);
    }

    _isLoaded = true;
    debugPrint("✅ All locations loaded successfully!");
    printLoadedRegions();
  }

  // Load single CSV file using fast_csv
  static Future<void> _loadSingleCsv(String regionName) async {
    try {
      final String csvString = await rootBundle.loadString(
        'assets/region/$regionName.csv',
      );

      // Tumia fast_csv kuchanganua CSV
      final csvData = fast_csv.parse(csvString);

      // Convert dynamic data to proper types
      List<LocationItem> items = [];

      // Ruka header row (index 0) na anza kutoka index 1
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length >= 7) {
          items.add(
            LocationItem(
              region: row[0].toString().trim(),
              postcodeRegion: row[1].toString().trim(),
              district: row[2].toString().trim(),
              postcodeDistrict: row[3].toString().trim(),
              division: row.length > 4
                  ? row[4].toString().trim()
                  : '', // 🆕 Tarafa
              postcodeDivision: row.length > 5
                  ? row[5].toString().trim()
                  : '', // 🆕 Postcode ya Tarafa
              ward: row.length > 6 ? row[6].toString().trim() : '', // Kata
              postcodeWard: row.length > 7
                  ? row[7].toString().trim()
                  : '', // Postcode ya Kata
              village: row.length > 8
                  ? row[8].toString().trim()
                  : '', // 🆕 Kijiji
              postcodeVillage: row.length > 9
                  ? row[9].toString().trim()
                  : '', // 🆕 Postcode ya Kijiji
              street: row.length > 10 ? row[10].toString().trim() : '', // Mtaa
              places: row.length > 11
                  ? row[11].toString().trim()
                  : '', // Places
            ),
          );
        }
      }

      if (items.isNotEmpty) {
        String regionKey = items.first.region;
        _allData[regionKey] = items;
        if (!_regions.contains(regionKey)) {
          _regions.add(regionKey);
        }
        debugPrint("✅ Loaded ${items.length} records from $regionName.csv");
      } else {
        debugPrint("⚠️ No data found in $regionName.csv");
      }
    } catch (e) {
      debugPrint("❌ Error loading $regionName.csv: $e");
    }
  }

  // ========== GETTERS ZOTE ==========

  // Get all regions sorted
  static List<String> getRegions() {
    return _regions.toList()..sort();
  }

  // Get districts for a specific region
  static List<String> getDistricts(String region) {
    final items = _allData[region];
    if (items == null) return [];
    return items.map((e) => e.district).toSet().toList()..sort();
  }

  // 🆕 Get divisions (Tarafa) for a specific region and district
  static List<String> getDivisions(String region, String district) {
    final items = _allData[region];
    if (items == null) return [];
    return items
        .where((e) => e.district == district && e.division.isNotEmpty)
        .map((e) => e.division)
        .toSet()
        .toList()
      ..sort();
  }

  // Get wards (Kata) for a specific region and district
  static List<String> getWards(String region, String district) {
    final items = _allData[region];
    if (items == null) return [];
    return items
        .where((e) => e.district == district && e.ward.isNotEmpty)
        .map((e) => e.ward)
        .toSet()
        .toList()
      ..sort();
  }

  // 🆕 Get wards (Kata) for a specific region, district, and division (Tarafa)
  static List<String> getWardsByDivision(
    String region,
    String district,
    String division,
  ) {
    final items = _allData[region];
    if (items == null) return [];
    return items
        .where(
          (e) =>
              e.district == district &&
              e.division == division &&
              e.ward.isNotEmpty,
        )
        .map((e) => e.ward)
        .toSet()
        .toList()
      ..sort();
  }

  // 🆕 Get villages (Vijiji) for a specific region, district, and ward
  static List<String> getVillages(String region, String district, String ward) {
    final items = _allData[region];
    if (items == null) return [];
    return items
        .where(
          (e) =>
              e.district == district && e.ward == ward && e.village.isNotEmpty,
        )
        .map((e) => e.village)
        .toSet()
        .toList()
      ..sort();
  }

  // Get streets (Mitaa) for a specific region, district, and ward
  static List<String> getStreets(String region, String district, String ward) {
    final items = _allData[region];
    if (items == null) return [];
    return items
        .where(
          (e) =>
              e.district == district && e.ward == ward && e.street.isNotEmpty,
        )
        .map((e) => e.street)
        .toSet()
        .toList()
      ..sort();
  }

  // 🆕 Get streets by village
  static List<String> getStreetsByVillage(
    String region,
    String district,
    String ward,
    String village,
  ) {
    final items = _allData[region];
    if (items == null) return [];
    return items
        .where(
          (e) =>
              e.district == district &&
              e.ward == ward &&
              e.village == village &&
              e.street.isNotEmpty,
        )
        .map((e) => e.street)
        .toSet()
        .toList()
      ..sort();
  }

  // Get full address string (updated with division and village)
  static String getFullAddress(
    String region,
    String district,
    String division,
    String ward,
    String village,
    String street,
  ) {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add("Mtaa: $street");
    if (village.isNotEmpty) parts.add("Kijiji: $village");
    if (ward.isNotEmpty) parts.add("Kata: $ward");
    if (division.isNotEmpty && division != 'Hakuna Tarafa') {
      parts.add("Tarafa: $division");
    }
    if (district.isNotEmpty) parts.add("Wilaya: $district");
    if (region.isNotEmpty) parts.add("Mkoa: $region");
    return parts.isNotEmpty ? parts.join(", ") : "Anwani haijakamilika";
  }

  // 🆕 Get short address (for map markers)
  static String getShortAddress(
    String region,
    String district,
    String ward,
    String street,
  ) {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (ward.isNotEmpty) parts.add(ward);
    if (district.isNotEmpty) parts.add(district);
    if (region.isNotEmpty) parts.add(region);
    return parts.join(", ");
  }

  // 🆕 Search locations by name
  static List<LocationItem> searchLocations(String query) {
    if (query.isEmpty) return [];

    final List<LocationItem> results = [];
    final String lowerQuery = query.toLowerCase();

    for (var items in _allData.values) {
      for (var item in items) {
        if (item.region.toLowerCase().contains(lowerQuery) ||
            item.district.toLowerCase().contains(lowerQuery) ||
            item.division.toLowerCase().contains(lowerQuery) ||
            item.ward.toLowerCase().contains(lowerQuery) ||
            item.village.toLowerCase().contains(lowerQuery) ||
            item.street.toLowerCase().contains(lowerQuery)) {
          results.add(item);
        }
      }
    }

    return results;
  }

  // 🆕 Get location by postcode
  static LocationItem? getLocationByPostcode(String postcode) {
    for (var items in _allData.values) {
      for (var item in items) {
        if (item.postcodeWard == postcode ||
            item.postcodeDistrict == postcode ||
            item.postcodeRegion == postcode ||
            item.postcodeDivision == postcode ||
            item.postcodeVillage == postcode) {
          return item;
        }
      }
    }
    return null;
  }

  // 🆕 Get statistics about loaded data
  static Map<String, int> getStatistics() {
    Map<String, int> stats = {};
    for (var entry in _allData.entries) {
      stats[entry.key] = entry.value.length;
    }
    return stats;
  }

  // Check if data is loaded
  static bool isLoaded() => _isLoaded;

  // Debug method - Print all loaded regions
  static void printLoadedRegions() {
    debugPrint("📊 Loaded Regions: ${_regions.length}");
    for (var region in _regions) {
      final items = _allData[region];
      if (items != null) {
        final districts = items.map((e) => e.district).toSet().length;
        final wards = items.map((e) => e.ward).toSet().length;
        final villages = items
            .where((e) => e.village.isNotEmpty)
            .map((e) => e.village)
            .toSet()
            .length;
        final streets = items
            .where((e) => e.street.isNotEmpty)
            .map((e) => e.street)
            .toSet()
            .length;

        debugPrint("  - $region: ${items.length} records");
        debugPrint(
          "      Districts: $districts, Wards: $wards, Villages: $villages, Streets: $streets",
        );
      }
    }
  }

  // 🆕 Reset service (for testing)
  static void reset() {
    _allData.clear();
    _regions.clear();
    _isLoaded = false;
    debugPrint("🔄 Location service reset");
  }

  // 🆕 Reload all data
  static Future<void> reload() async {
    reset();
    await loadAllLocations();
  }
}
