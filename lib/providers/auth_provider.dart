import 'package:flutter/material.dart';

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

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get token => _token;
  String? get phone => _phone;
  String? get avatarUrl => _avatarUrl;
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
    String? avatarUrl,
    bool isProfileComplete = false,
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

    debugPrint('User logged in: $_userName');
    debugPrint('User Role: $_userRole');
    debugPrint('Profile Complete: $_isProfileComplete');

    notifyListeners();
  }

  void setProfileComplete(bool complete) {
    _isProfileComplete = complete;
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
    _avatarUrl = null;
    _isProfileComplete = false;

    debugPrint('User logged out');
    notifyListeners();
  }
}
