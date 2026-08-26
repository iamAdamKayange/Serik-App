import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/rental_model.dart';

/// Offline Service for handling data caching and offline functionality
class OfflineService {
  OfflineService._();
  
  static final OfflineService instance = OfflineService._();
  
  static const String _cachedHousesKey = 'cached_houses';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _offlineModeKey = 'offline_mode_enabled';
  
  bool _isOfflineMode = false;
  bool _hasCachedData = false;
  DateTime? _lastSyncTime;
  
  bool get isOfflineMode => _isOfflineMode;
  bool get hasCachedData => _hasCachedData;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Initialize offline service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOfflineMode = prefs.getBool(_offlineModeKey) ?? false;
      _hasCachedData = prefs.containsKey(_cachedHousesKey);
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }
    } catch (e) {
      print('Error initializing offline service: $e');
    }
  }
  
  /// Cache houses for offline use
  Future<void> cacheHouses(List<dynamic> housesJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedHousesKey, jsonEncode(housesJson));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      _hasCachedData = true;
      _lastSyncTime = DateTime.now();
      print('Houses cached successfully for offline use');
    } catch (e) {
      print('Error caching houses: $e');
    }
  }
  
  /// Get cached houses
  Future<List<dynamic>> getCachedHouses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedHousesKey);
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        if (decoded is List) {
          return decoded.cast<dynamic>();
        }
      }
      return [];
    } catch (e) {
      print('Error getting cached houses: $e');
      return [];
    }
  }
  
  /// Convert cached houses to RentalSpot objects
  Future<List<RentalSpot>> getCachedRentalSpots() async {
    try {
      final housesJson = await getCachedHouses();
      return housesJson.map((json) {
        final houseData = HouseData.fromJson(json as Map<String, dynamic>);
        return RentalSpot.fromHouseData(houseData);
      }).toList();
    } catch (e) {
      print('Error converting cached houses to rental spots: $e');
      return [];
    }
  }
  
  /// Set offline mode
  Future<void> setOfflineMode(bool offline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, offline);
      _isOfflineMode = offline;
      print('Offline mode set to: $offline');
    } catch (e) {
      print('Error setting offline mode: $e');
    }
  }
  
  /// Clear cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedHousesKey);
      await prefs.remove(_lastSyncKey);
      _hasCachedData = false;
      _lastSyncTime = null;
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
  
  /// Check if data needs refresh (older than 1 hour)
  bool needsRefresh() {
    if (_lastSyncTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    return difference.inHours >= 1;
  }
  
  /// Get cache age in minutes
  int getCacheAgeInMinutes() {
    if (_lastSyncTime == null) return -1;
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    return difference.inMinutes;
  }
  
  /// Format cache age for display
  String getCacheAgeFormatted() {
    final minutes = getCacheAgeInMinutes();
    if (minutes < 1) return 'hivi punde';
    if (minutes < 60) return 'dakika $minutes zilizopita';
    final hours = minutes ~/ 60;
    if (hours < 24) return 'saa $hours zilizopita';
    final days = hours ~/ 24;
    return 'siku $days zilizopita';
  }
}
