// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userRole; //
  String? _token;
  String? _phone;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  String? get token => _token;
  String? get phone => _phone;

  /// 🔥 Check if user is landlord
  bool get isLandlord => _userRole == 'landlord' || _userRole == 'admin';

  /// 🔥 Check if user is normal user
  bool get isNormalUser => _userRole == 'normal';

  void login({
    required String userId,
    required String userName,
    required String userEmail,
    String? userRole,
    String? token,
    String? phone,
  }) {
    _isLoggedIn = true;
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _userRole = userRole ?? 'normal'; // Default ni normal user
    _token = token;
    _phone = phone;

    debugPrint('✅ User logged in: $_userName');
    debugPrint('🎭 User Role: $_userRole');

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

    debugPrint('🔓 User logged out');
    notifyListeners();
  }
}
