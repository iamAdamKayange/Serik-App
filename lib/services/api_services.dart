import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://serkapp-backend.onrender.com';
  static const String apiPrefix = '/api';

  static final _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    debugPrint(
      '🔐 _getHeaders: token = ${token != null ? "present (${token.length} chars)" : "null"}',
    );
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================

  /// Register new user
  static Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String role = 'normal',
  }) async {
    final url = Uri.parse('$baseUrl$apiPrefix/auth/register');
    debugPrint('📝 Registering user: $email, role: $role');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone ?? '',
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      debugPrint('✅ Registration successful, token received');
      return data;
    } else {
      debugPrint('❌ Register failed: ${response.body}');
      return null;
    }
  }

  /// Login user
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl$apiPrefix/auth/login');
    debugPrint('🔐 Logging in: $email');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final role = data['role'];
      debugPrint(
        '✅ Login successful, role: $role, token length: ${token.length}',
      );
      await _storage.write(key: 'auth_token', value: token);
      return data;
    } else {
      debugPrint('❌ Login failed: ${response.body}');
      return null;
    }
  }

  /// Get current user profile (requires token)
  static Future<Map<String, dynamic>?> getMe() async {
    final url = Uri.parse('$baseUrl$apiPrefix/auth/me');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint(
        '👤 getMe: ${data['first_name']} ${data['last_name']}, role: ${data['role']}',
      );
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('❌ getMe: Token invalid or expired');
      return null;
    } else {
      debugPrint('❌ getMe failed: ${response.statusCode}');
      return null;
    }
  }

  /// Logout - clear stored token
  static Future<void> logout() async {
    debugPrint('🔓 Logging out, deleting token');
    await _storage.delete(key: 'auth_token');
  }

  // ==================== HOUSES ====================

  /// Get all houses (public)
  static Future<List<dynamic>> getAllHouses() async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  /// Get single house by ID
  static Future<Map<String, dynamic>?> getHouseById(String id) async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Get houses for logged-in landlord
  static Future<List<dynamic>> getMyHouses() async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/landlord/my-houses');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    debugPrint('❌ getMyHouses failed: ${response.statusCode}');
    return [];
  }

  /// Create a new house (landlord only)
  static Future<Map<String, dynamic>?> createHouse(
    Map<String, dynamic> houseData,
  ) async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses');
    final headers = await _getHeaders();
    debugPrint('🏠 Creating house: ${houseData['name']}');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(houseData),
    );
    if (response.statusCode == 201) {
      debugPrint('✅ House created successfully');
      return jsonDecode(response.body);
    } else {
      debugPrint(
        '❌ Create house failed (${response.statusCode}): ${response.body}',
      );
      return null;
    }
  }

  /// Update house (landlord only)
  static Future<Map<String, dynamic>?> updateHouse(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
    final headers = await _getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Delete house (landlord only)
  static Future<bool> deleteHouse(String id) async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 200;
  }

  /// Check if current token is valid and user is landlord
  static Future<bool> isLandlordTokenValid() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      debugPrint('❌ isLandlordTokenValid: No token found');
      return false;
    }
    debugPrint('🔍 isLandlordTokenValid: Token exists, length ${token.length}');

    final user = await getMe();
    if (user == null) {
      debugPrint('❌ isLandlordTokenValid: getMe failed (token invalid?)');
      return false;
    }

    final role = user['role'] as String?;
    final isValid = role == 'landlord' || role == 'admin';
    debugPrint('✅ isLandlordTokenValid: role=$role, isValid=$isValid');
    return isValid;
  }

  // ==================== MEDIA UPLOAD (Images & Videos) ====================

  static Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    debugPrint(
      '🔑 getToken: ${token != null ? "token present (${token.length} chars)" : "null"}',
    );
    return token;
  }

  /// Upload multiple images/videos to Cloudinary
  static Future<List<Map<String, dynamic>>> uploadMedia(
    List<http.MultipartFile> files,
  ) async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/upload-media');

    final token = await _storage.read(key: 'auth_token');
    debugPrint(
      '📤 uploadMedia: token = ${token != null ? "YES (length ${token.length})" : "NO"}',
    );

    if (token == null || token.isEmpty) {
      throw Exception("Hakuna token ya kuingia. Tafadhali ingia tena.");
    }

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    // DO NOT set Content-Type – multipart will set boundary automatically

    request.files.addAll(files);
    debugPrint('📤 Sending ${files.length} file(s) to $url');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('📥 Upload response status: ${response.statusCode}');
    debugPrint('📥 Upload response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ Upload successful: ${data['files']?.length ?? 0} files');
      return List<Map<String, dynamic>>.from(data['files']);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Token is invalid or lacks permissions
      debugPrint('❌ Upload failed: ${response.statusCode} - ${response.body}');
      await _storage.delete(key: 'auth_token');
      throw Exception("Uidhinishaji umeshindwa. Tafadhali ingia tena.");
    } else {
      debugPrint('❌ Upload server error: ${response.statusCode}');
      throw Exception(
        "Server error: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
