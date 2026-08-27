import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  String? _token;
  String? _phone;

  // 🔥 Add this field for profile completion status
  bool _isProfileComplete = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get token => _token;
  String? get phone => _phone;

  // 🔥 Add this getter
  bool get isProfileComplete => _isProfileComplete;

  bool get isLandlord => _userRole == 'landlord' || _userRole == 'admin';
  bool get isNormalUser => _userRole == 'normal';

  void login({
    required String userId,
    required String userName,
    required String userEmail,
    String? userRole,
    String? token,
    String? phone,
    bool isProfileComplete = false, // 🔥 Add this parameter
  }) {
    _isLoggedIn = true;
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _userRole = userRole ?? 'normal';
    _token = token;
    _phone = phone;
    _isProfileComplete = isProfileComplete; // 🔥 Set profile status

    debugPrint('✅ User logged in: $_userName');
    debugPrint('🎭 User Role: $_userRole');
    debugPrint('📋 Profile Complete: $_isProfileComplete');

    notifyListeners();
  }

  // 🔥 Add method to update profile completion status
  void setProfileComplete(bool complete) {
    _isProfileComplete = complete;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    _token = null;
    _phone = null;
    _isProfileComplete = false; // 🔥 Reset profile status

    debugPrint('🔓 User logged out');
    notifyListeners();
  }
}
