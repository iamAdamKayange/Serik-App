import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://serkapp-backend.onrender.com';
  static const String apiPrefix = '/api';
  static const Duration timeout = Duration(seconds: 30);

  static final _storage = FlutterSecureStorage();
  static const _housesCacheKey = 'api_cache_all_houses';
  static const _videoFeedCacheKey = 'api_cache_video_feed';
  static const _notificationsCacheKey = 'api_cache_notifications';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/auth/register');
      debugPrint('📝 Registering user: $email, role: $role');
      final response = await http
          .post(
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
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Registration successful');
        return data;
      } else {
        debugPrint(
          '❌ Register failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Register error: $e');
      return null;
    }
  }

  /// Login user
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/auth/login');
      debugPrint('🔐 Logging in: $email');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];
        debugPrint('✅ Login successful, role: $role');
        await _storage.write(key: 'auth_token', value: token);
        return data;
      } else {
        debugPrint('❌ Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return null;
    }
  }

  /// Get current user profile (requires token)
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/auth/me');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('👤 getMe: ${data['first_name']} ${data['last_name']}');
        return data;
      } else if (response.statusCode == 401) {
        debugPrint('❌ getMe: Token invalid or expired');
        return null;
      } else {
        debugPrint('❌ getMe failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ getMe error: $e');
      return null;
    }
  }

  /// Logout - clear stored token
  static Future<void> logout() async {
    debugPrint('🔓 Logging out');
    await _storage.delete(key: 'auth_token');
  }

  // ==================== HOUSES ====================

  /// Get all houses (public) - Full data with images
  static Future<List<dynamic>> getAllHouses() async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses');
    final cached = await _readListCache(_housesCacheKey);
    if (cached != null) {
      _refreshListCache(key: _housesCacheKey, url: url);
      return cached;
    }

    try {
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        await _writeListCache(_housesCacheKey, data);
        return data;
      }
      debugPrint('❌ getAllHouses failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getAllHouses error: $e');
      return [];
    }
  }

  /// Get lightweight video feed (FAST - only videos and basic info)
  static Future<List<dynamic>> getVideoFeed() async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/feed/videos');
    final cached = await _readListCache(_videoFeedCacheKey);
    if (cached != null) {
      _refreshListCache(key: _videoFeedCacheKey, url: url);
      return cached;
    }

    try {
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        await _writeListCache(_videoFeedCacheKey, data);
        debugPrint('✅ Video feed loaded: ${data.length} items');
        return data;
      }
      debugPrint('❌ getVideoFeed failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getVideoFeed error: $e');
      return [];
    }
  }

  static Future<List<dynamic>?> _readListCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } catch (e) {
      debugPrint('Cache read failed for $key: $e');
      return null;
    }
  }

  static Future<void> _writeListCache(String key, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Cache write failed for $key: $e');
    }
  }

  static void _refreshListCache({
    required String key,
    required Uri url,
    Map<String, String>? headers,
  }) {
    unawaited(
      http
          .get(url, headers: headers)
          .timeout(timeout)
          .then((response) {
            if (response.statusCode == 200) {
              final decoded = jsonDecode(response.body);
              if (decoded is List) {
                return _writeListCache(key, decoded);
              }
            }
          })
          .catchError((e) {
            debugPrint('Background cache refresh failed for $key: $e');
          }),
    );
  }

  // ==================== NOTIFICATIONS ====================

  static Future<List<dynamic>> getNotifications({int limit = 50}) async {
    final url = Uri.parse('$baseUrl$apiPrefix/notifications?limit=$limit');
    final cached = await _readListCache(_notificationsCacheKey);
    if (cached != null) {
      _refreshListCache(key: _notificationsCacheKey, url: url);
      return cached;
    }

    try {
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        await _writeListCache(_notificationsCacheKey, data);
        return data;
      }
      debugPrint('getNotifications failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('getNotifications error: $e');
      return [];
    }
  }

  static Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/notifications/devices');
      final body = <String, dynamic>{
        'token': token,
        'platform': platform,
      };
      if (appVersion != null) body['appVersion'] = appVersion;
      if (userId != null) body['userId'] = userId;

      await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (e) {
      debugPrint('registerDeviceToken error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getSmartAlertPreferences({
    required String token,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/notifications/preferences?token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('getSmartAlertPreferences failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('getSmartAlertPreferences error: $e');
      return null;
    }
  }

  static Future<bool> saveSmartAlertPreferences({
    required String token,
    required bool enabled,
    required List<String> regions,
    required List<String> districts,
    required List<String> houseTypes,
    double? minRent,
    double? maxRent,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/notifications/preferences');
      final body = <String, dynamic>{
        'token': token,
        'enabled': enabled,
        'regions': regions,
        'districts': districts,
        'houseTypes': houseTypes,
      };
      if (minRent != null) body['minRent'] = minRent;
      if (maxRent != null) body['maxRent'] = maxRent;

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('saveSmartAlertPreferences error: $e');
      return false;
    }
  }

  static Future<bool> isHouseSaved({
    required String token,
    required String houseId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/notifications/saved-houses/$houseId?token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['saved'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('isHouseSaved error: $e');
      return false;
    }
  }

  static Future<bool> saveHouseForAlerts({
    required String token,
    required String houseId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/notifications/saved-houses');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'houseId': houseId}),
          )
          .timeout(timeout);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('saveHouseForAlerts error: $e');
      return false;
    }
  }

  static Future<bool> removeSavedHouse({
    required String token,
    required String houseId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/notifications/saved-houses/$houseId?token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await http.delete(url).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('removeSavedHouse error: $e');
      return false;
    }
  }

  /// Get single house by ID
  static Future<Map<String, dynamic>?> getHouseById(String id) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ getHouseById error: $e');
      return null;
    }
  }

  /// Get houses for logged-in landlord
  static Future<List<dynamic>> getMyHouses() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/landlord/my-houses');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('❌ getMyHouses failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getMyHouses error: $e');
      return [];
    }
  }

  /// Create a new house (landlord only)
  static Future<Map<String, dynamic>?> createHouse(
    Map<String, dynamic> houseData,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses');
      final headers = await _getHeaders();
      debugPrint('🏠 Creating house: ${houseData['name']}');
      final response = await http
          .post(url, headers: headers, body: jsonEncode(houseData))
          .timeout(timeout);
      if (response.statusCode == 201) {
        debugPrint('✅ House created successfully');
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Create house failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ createHouse error: $e');
      return null;
    }
  }

  /// Update house (landlord only)
  static Future<Map<String, dynamic>?> updateHouse(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
      final headers = await _getHeaders();
      final response = await http
          .put(url, headers: headers, body: jsonEncode(updates))
          .timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ updateHouse error: $e');
      return null;
    }
  }

  /// Delete house (landlord only)
  static Future<bool> deleteHouse(String id) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
      final headers = await _getHeaders();
      final response = await http
          .delete(url, headers: headers)
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ deleteHouse error: $e');
      return false;
    }
  }

  /// Check if current token is valid and user is landlord
  static Future<bool> isLandlordTokenValid() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        debugPrint('❌ isLandlordTokenValid: No token found');
        return false;
      }

      final user = await getMe();
      if (user == null) return false;

      final role = user['role'] as String?;
      final isValid = role == 'landlord' || role == 'admin';
      debugPrint('✅ isLandlordTokenValid: role=$role, isValid=$isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ isLandlordTokenValid error: $e');
      return false;
    }
  }

  // ==================== MEDIA UPLOAD ====================

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Upload multiple images/videos to DigitalOcean Spaces
  static Future<List<Map<String, dynamic>>> uploadMedia(
    List<http.MultipartFile> files,
  ) async {
    final url = Uri.parse('$baseUrl$apiPrefix/houses/upload-media');

    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("Hakuna token ya kuingia. Tafadhali ingia tena.");
    }

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.addAll(files);
    debugPrint('📤 Sending ${files.length} file(s)');

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ Upload successful: ${data['files']?.length ?? 0} files');
      return List<Map<String, dynamic>>.from(data['files']);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('❌ Upload failed: ${response.statusCode}');
      await _storage.delete(key: 'auth_token');
      throw Exception("Uidhinishaji umeshindwa. Tafadhali ingia tena.");
    } else {
      debugPrint('❌ Upload server error: ${response.statusCode}');
      throw Exception(
        "Server error: ${response.statusCode} - ${response.body}",
      );
    }
  }

  /// Upload a single thumbnail for a video
  static Future<String?> uploadThumbnail(XFile thumbnailFile) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/upload-thumbnail');
      final token = await _storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception("Hakuna token ya kuingia. Tafadhali ingia tena.");
      }

      final bytes = await thumbnailFile.readAsBytes();
      final mimeType = lookupMimeType(thumbnailFile.path) ?? 'image/jpeg';

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'thumbnail',
          bytes,
          filename: thumbnailFile.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      debugPrint('📤 Uploading thumbnail: ${thumbnailFile.name}');

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] as String?;
        debugPrint('✅ Thumbnail uploaded: $url');
        return url;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ Thumbnail upload failed: ${response.statusCode}');
        await _storage.delete(key: 'auth_token');
        throw Exception("Uidhinishaji umeshindwa. Tafadhali ingia tena.");
      } else {
        debugPrint('❌ Thumbnail upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ uploadThumbnail error: $e');
      return null;
    }
  }

  // ==================== COMMENTS & LIKES ====================

  /// Get comments for a video
  static Future<List<dynamic>> getVideoComments(String videoId) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/comments/video/$videoId');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint(
        '⚠️ getVideoComments: ${response.statusCode} - returning empty',
      );
      return [];
    } catch (e) {
      debugPrint('⚠️ getVideoComments error: $e');
      return [];
    }
  }

  /// Get comments for a house
  static Future<List<dynamic>> getHouseComments(String houseId) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/comments/house/$houseId');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('⚠️ getHouseComments: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('⚠️ getHouseComments error: $e');
      return [];
    }
  }

  /// Create a new comment or reply
  static Future<Map<String, dynamic>?> createComment({
    required String videoId,
    required String houseId,
    required String content,
    String? parentId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/comments');
      final headers = await _getHeaders();
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'videoId': videoId,
              'houseId': houseId,
              'content': content,
              'parentId': ?parentId,
            }),
          )
          .timeout(timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      debugPrint(
        '❌ createComment failed: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('❌ createComment error: $e');
      return null;
    }
  }

  /// Delete a comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/comments/$commentId');
      final headers = await _getHeaders();
      final response = await http
          .delete(url, headers: headers)
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ deleteComment error: $e');
      return false;
    }
  }

  /// Toggle like on a comment
  static Future<Map<String, dynamic>?> toggleCommentLike(
    String commentId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/comments/$commentId/like');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('❌ toggleCommentLike failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ toggleCommentLike error: $e');
      return null;
    }
  }

  /// Toggle like on a video
  static Future<Map<String, dynamic>?> toggleVideoLike(String videoId) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/comments/video/$videoId/like');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint(
        '⚠️ toggleVideoLike: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('⚠️ toggleVideoLike error: $e');
      return null;
    }
  }

  /// Get video like status
  static Future<Map<String, dynamic>?> getVideoLikeStatus(
    String videoId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/comments/video/$videoId/like-status',
      );
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('⚠️ getVideoLikeStatus: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('⚠️ getVideoLikeStatus error: $e');
      return null;
    }
  }

  // ==================== LOCATIONS ====================

  /// Get all regions
  static Future<List<String>> getRegions() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/locations/regions');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('❌ getRegions error: $e');
      return [];
    }
  }

  /// Get districts by region
  static Future<List<String>> getDistricts(String region) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/locations/regions/$region/districts',
      );
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('❌ getDistricts error: $e');
      return [];
    }
  }

  /// Get wards by region and district
  static Future<List<String>> getWards(String region, String district) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/locations/regions/$region/districts/$district/wards',
      );
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('❌ getWards error: $e');
      return [];
    }
  }

  /// Get streets by region, district and ward
  static Future<List<String>> getStreets(
    String region,
    String district,
    String ward,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/locations/regions/$region/districts/$district/wards/$ward/streets',
      );
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('❌ getStreets error: $e');
      return [];
    }
  }

  // ==================== RENTAL AGREEMENTS ====================

  /// Create rental agreement request (tenant)
  static Future<Map<String, dynamic>?> createAgreement({
    required String houseId,
    required String startDate,
    required String endDate,
    required double monthlyRent,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/agreements');
      final headers = await _getHeaders();
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'houseId': houseId,
              'startDate': startDate,
              'endDate': endDate,
              'monthlyRent': monthlyRent,
            }),
          )
          .timeout(timeout);
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('❌ createAgreement error: $e');
      return null;
    }
  }

  /// Get agreements for tenant (my requests)
  static Future<List<dynamic>> getMyAgreements() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/agreements/tenant');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('❌ getMyAgreements error: $e');
      return [];
    }
  }

  /// Get agreements for landlord (requests for their houses)
  static Future<List<dynamic>> getLandlordAgreements() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/agreements/landlord');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('❌ getLandlordAgreements error: $e');
      return [];
    }
  }

  /// Update agreement status (landlord)
  static Future<bool> updateAgreementStatus(String id, String status) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/agreements/$id/status');
      final headers = await _getHeaders();
      final response = await http
          .put(url, headers: headers, body: jsonEncode({'status': status}))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ updateAgreementStatus error: $e');
      return false;
    }
  }
}
