import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  String? _token;
  String? _phone;
  String? _avatarUrl;
  bool _isProfileComplete = false;
  String? _preferredLanguage;

  // Secure storage for sensitive data
  static const _secureStorage = FlutterSecureStorage();

  // SharedPreferences for non-sensitive data
  SharedPreferences? _prefs;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get token => _token;
  String? get phone => _phone;
  String? get avatarUrl => _avatarUrl;
  bool get isProfileComplete => _isProfileComplete;
  String? get preferredLanguage => _preferredLanguage;

  bool get isLandlord => _userRole == 'landlord' || _userRole == 'admin';
  bool get isNormalUser => _userRole == 'normal';
  bool get isAdmin => _userRole == 'admin';

  // Initialize and load persisted session
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedSession();
  }

  Future<void> _loadPersistedSession() async {
    try {
      // Check if user was logged in
      final wasLoggedIn = _prefs?.getBool('isLoggedIn') ?? false;
      
      if (wasLoggedIn) {
        // Load sensitive data from secure storage
        final token = await _secureStorage.read(key: 'auth_token');
        final userId = await _secureStorage.read(key: 'user_id');
        
        // Load non-sensitive data from SharedPreferences
        final userName = _prefs?.getString('user_name');
        final userEmail = _prefs?.getString('user_email');
        final userRole = _prefs?.getString('user_role');
        final phone = _prefs?.getString('user_phone');
        final avatarUrl = _prefs?.getString('user_avatar');
        final isProfileComplete = _prefs?.getBool('is_profile_complete') ?? false;
        final preferredLanguage = _prefs?.getString('preferred_language');

        if (token != null && userId != null) {
          _isLoggedIn = true;
          _token = token;
          _userId = userId;
          _userName = userName;
          _userEmail = userEmail;
          _userRole = userRole;
          _phone = phone;
          _avatarUrl = avatarUrl;
          _isProfileComplete = isProfileComplete;
          _preferredLanguage = preferredLanguage;

          debugPrint('🔄 Session restored for: $_userName');
          debugPrint('🎭 Role: $_userRole');
          debugPrint('🌐 Language: $_preferredLanguage');
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading persisted session: $e');
      // Clear corrupted session
      await _clearPersistedSession();
    }
  }

  Future<void> _persistSession() async {
    try {
      // Persist sensitive data in secure storage
      await _secureStorage.write(key: 'auth_token', value: _token ?? '');
      await _secureStorage.write(key: 'user_id', value: _userId ?? '');

      // Persist non-sensitive data in SharedPreferences
      await _prefs?.setBool('isLoggedIn', _isLoggedIn);
      await _prefs?.setString('user_name', _userName ?? '');
      await _prefs?.setString('user_email', _userEmail ?? '');
      await _prefs?.setString('user_role', _userRole ?? '');
      await _prefs?.setString('user_phone', _phone ?? '');
      await _prefs?.setString('user_avatar', _avatarUrl ?? '');
      await _prefs?.setBool('is_profile_complete', _isProfileComplete);
      await _prefs?.setString('preferred_language', _preferredLanguage ?? 'sw');

      debugPrint('💾 Session persisted');
    } catch (e) {
      debugPrint('Error persisting session: $e');
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'user_id');

      // Clear SharedPreferences
      await _prefs?.remove('isLoggedIn');
      await _prefs?.remove('user_name');
      await _prefs?.remove('user_email');
      await _prefs?.remove('user_role');
      await _prefs?.remove('user_phone');
      await _prefs?.remove('user_avatar');
      await _prefs?.remove('is_profile_complete');
      await _prefs?.remove('preferred_language');

      debugPrint('🗑️ Session cleared');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  void login({
    required String userId,
    required String userName,
    required String userEmail,
    String? userRole,
    String? token,
    String? phone,
    String? avatarUrl,
    bool isProfileComplete = false,
    String? preferredLanguage,
  }) {
    _isLoggedIn = true;
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _userRole = userRole ?? 'normal';
    _token = token;
    _phone = phone;
    _avatarUrl = avatarUrl;
    _isProfileComplete = isProfileComplete;
    _preferredLanguage = preferredLanguage ?? 'sw';

    debugPrint('User logged in: $_userName');
    debugPrint('User Role: $_userRole');
    debugPrint('Profile Complete: $_isProfileComplete');
    debugPrint('Preferred Language: $_preferredLanguage');

    // Persist session asynchronously
    _persistSession();

    notifyListeners();
  }

  void setProfileComplete(bool complete) {
    _isProfileComplete = complete;
    _persistSession();
    notifyListeners();
  }

  void updateProfile({
    String? userName,
    String? userEmail,
    String? userRole,
    String? phone,
    String? avatarUrl,
  }) {
    if (userName != null) _userName = userName;
    if (userEmail != null) _userEmail = userEmail;
    if (userRole != null) _userRole = userRole;
    if (phone != null) _phone = phone;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    _persistSession();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    _token = null;
    _phone = null;
    _avatarUrl = null;
    _isProfileComplete = false;
    // Keep language preference on logout
    final savedLanguage = _preferredLanguage;

    debugPrint('User logged out');

    // Clear persisted session but keep language
    await _clearPersistedSession();
    
    // Restore language preference
    _preferredLanguage = savedLanguage;
    await _prefs?.setString('preferred_language', savedLanguage ?? 'sw');

    notifyListeners();
  }
}
