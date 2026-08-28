import 'dart:convert';
import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serik/services/realtime_service.dart';

class ApiService {
  static String get baseUrl {
    // Use environment variable or fallback to production URL
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    return envBaseUrl.isNotEmpty ? envBaseUrl : 'https://serkapp-backend.onrender.com';
  }
  
  static const String apiPrefix = '/api';
  static const Duration timeout = Duration(seconds: 30);

  static final _storage = FlutterSecureStorage();
  static const _housesCacheKey = 'api_cache_all_houses';
  static const _videoFeedCacheKey = 'api_cache_video_feed';
  static const _notificationsCacheKey = 'api_cache_notifications';
  static const _myHousesCacheKey = 'api_cache_my_houses';
  static const _houseDetailCachePrefix = 'api_cache_house_';
  static const _smartAlertPrefsPrefix = 'api_cache_smart_alert_';
  static const _notificationInstallCutoffKey =
      'notification_install_cutoff_at';

  static String _houseDetailCacheKey(String id) => '$_houseDetailCachePrefix$id';

  static String _smartAlertPrefsCacheKey(String token) =>
      '$_smartAlertPrefsPrefix${token.hashCode}';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': '1.0.0',
      'X-Platform': 'mobile',
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

  /// Update current user profile
  static Future<Map<String, dynamic>?> updateMe({
    String? firstName,
    String? lastName,
    String? phone,
    XFile? avatarFile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/auth/me');
      if (avatarFile == null) {
        final headers = await _getHeaders();
        final response = await http
            .put(
              url,
              headers: headers,
              body: jsonEncode({
                if (firstName != null) 'firstName': firstName,
                if (lastName != null) 'lastName': lastName,
                if (phone != null) 'phone': phone,
              }),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        debugPrint('⚠️ updateMe failed: ${response.statusCode} - ${response.body}');
        return null;
      }

      final headers = await _getHeaders();
      headers.remove('Content-Type');

      final request = http.MultipartRequest('PUT', url);
      request.headers.addAll(headers);
      if (firstName != null) request.fields['firstName'] = firstName;
      if (lastName != null) request.fields['lastName'] = lastName;
      if (phone != null) request.fields['phone'] = phone;

      final mimeType = lookupMimeType(avatarFile.path);
      final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: mediaType,
          filename: path.basename(avatarFile.path),
        ),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('⚠️ updateMe failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('⚠️ updateMe error: $e');
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

  static Future<void> _clearListCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Cache clear failed for $key: $e');
    }
  }

  static Future<void> _clearHouseCaches({String? houseId}) async {
    await _clearListCache(_housesCacheKey);
    await _clearListCache(_videoFeedCacheKey);
    await _clearListCache(_myHousesCacheKey);
    if (houseId != null && houseId.isNotEmpty) {
      await _clearListCache(_houseDetailCacheKey(houseId));
    }
  }

  static Future<Map<String, dynamic>?> _readMapCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('Map cache read failed for $key: $e');
      return null;
    }
  }

  static Future<void> _writeMapCache(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Map cache write failed for $key: $e');
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
    final fcmToken = await _readFcmToken();
    final queryParameters = <String, String>{'limit': limit.toString()};
    if (fcmToken != null) {
      queryParameters['token'] = fcmToken;
    }
    final installCutoffAt = await _readNotificationInstallCutoff();
    if (installCutoffAt != null && installCutoffAt.isNotEmpty) {
      queryParameters['installCutoffAt'] = installCutoffAt;
    }
    
    // Add user role to filter notifications
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        final payload = _parseJwt(token);
        final userId = payload['id']?.toString();
        final userRole = payload['role'] as String?;
        if (userId != null && userId.isNotEmpty) {
          queryParameters['userId'] = userId;
        }
        if (userRole != null) {
          queryParameters['userRole'] = userRole;
        }
      } catch (e) {
        debugPrint('Failed to parse user role from token: $e');
      }
    }
    
    final url = Uri.parse('$baseUrl$apiPrefix/notifications').replace(
      queryParameters: queryParameters,
    );

    try {
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        await _writeListCache(_notificationsCacheKey, data);
        return data;
      }
      debugPrint('getNotifications failed: ${response.statusCode}');
      return await _readListCache(_notificationsCacheKey) ?? [];
    } catch (e) {
      debugPrint('getNotifications error: $e');
      return await _readListCache(_notificationsCacheKey) ?? [];
    }
  }

  static Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    final decoded = convert.base64.decode(normalized);
    return jsonDecode(convert.utf8.decode(decoded));
  }

  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final fcmToken = await _readFcmToken();
      
      if (fcmToken == null) {
        debugPrint('deleteNotification: FCM token not available');
        // Try without FCM token for auth-based deletion
        final url = Uri.parse('$baseUrl$apiPrefix/notifications/$notificationId');
        final response = await http.delete(url, headers: headers).timeout(timeout);
        if (response.statusCode == 200) {
          await _clearListCache(_notificationsCacheKey);
          RealtimeService.instance.emit('notification:changed', {
            'action': 'deleted',
            'notificationId': notificationId,
          });
          return true;
        }
        debugPrint('deleteNotification failed: ${response.statusCode}');
        return false;
      }
      
      final url = Uri.parse(
        '$baseUrl$apiPrefix/notifications/$notificationId',
      ).replace(queryParameters: {'token': fcmToken});
      final response = await http.delete(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        await _clearListCache(_notificationsCacheKey);
        RealtimeService.instance.emit('notification:changed', {
          'action': 'deleted',
          'notificationId': notificationId,
        });
        return true;
      }
      debugPrint('deleteNotification failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('deleteNotification error: $e');
      return false;
    }
  }

  static Future<String?> _readFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token == null || token.isEmpty ? null : token;
    } catch (e) {
      debugPrint('readFcmToken error: $e');
      return null;
    }
  }

  static Future<String?> _readNotificationInstallCutoff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_notificationInstallCutoffKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final now = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(_notificationInstallCutoffKey, now);
      return now;
    } catch (e) {
      debugPrint('readNotificationInstallCutoff error: $e');
      return null;
    }
  }

  static Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? userId,
    String? installCutoffAt,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/notifications/devices');
      final body = <String, dynamic>{
        'token': token,
        'platform': platform,
      };
      if (appVersion != null) body['appVersion'] = appVersion;
      if (userId != null) body['userId'] = userId;
      if (installCutoffAt != null) body['installCutoffAt'] = installCutoffAt;

      await http
          .post(
            url,
            headers: await _getHeaders(),
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
    final cacheKey = _smartAlertPrefsCacheKey(token);
    try {
      final url = Uri.parse(
        '$baseUrl$apiPrefix/notifications/preferences?token=${Uri.encodeQueryComponent(token)}',
      );
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _writeMapCache(cacheKey, data);
        return data;
      }
      debugPrint('getSmartAlertPreferences failed: ${response.statusCode}');
      return await _readMapCache(cacheKey);
    } catch (e) {
      debugPrint('getSmartAlertPreferences error: $e');
      return await _readMapCache(cacheKey);
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
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      final ok = response.statusCode == 200;
      if (ok) {
        await _writeMapCache(_smartAlertPrefsCacheKey(token), body);
        RealtimeService.instance.emit('notification:changed', {
          'action': 'preferences_updated',
          'token': token,
        });
      }
      return ok;
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
    final cacheKey = _houseDetailCacheKey(id);
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/$id');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _writeMapCache(cacheKey, data);
        return data;
      }
      return await _readMapCache(cacheKey);
    } catch (e) {
      debugPrint('❌ getHouseById error: $e');
      return await _readMapCache(cacheKey);
    }
  }

  /// Get houses for logged-in landlord
  static Future<List<dynamic>> getMyHouses() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/houses/landlord/my-houses');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        await _writeListCache(_myHousesCacheKey, data);
        return data;
      }
      debugPrint('❌ getMyHouses failed: ${response.statusCode}');
      return await _readListCache(_myHousesCacheKey) ?? [];
    } catch (e) {
      debugPrint('❌ getMyHouses error: $e');
      return await _readListCache(_myHousesCacheKey) ?? [];
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
        await _clearHouseCaches();
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        RealtimeService.instance.emit('house:changed', {
          'action': 'created',
          'houseId': data['id']?.toString(),
        });
        return data;
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
        await _clearHouseCaches(houseId: id);
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        RealtimeService.instance.emit('house:changed', {
          'action': 'updated',
          'houseId': id,
        });
        return data;
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
      final ok = response.statusCode == 200;
      if (ok) {
        await _clearHouseCaches(houseId: id);
        RealtimeService.instance.emit('house:changed', {
          'action': 'deleted',
          'houseId': id,
        });
      }
      return ok;
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

  // ==================== LANDLORD VERIFICATION ====================

  /// Get overall verification status
  static Future<Map<String, dynamic>?> getVerificationStatus() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/status');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('⚠️ getVerificationStatus: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('⚠️ getVerificationStatus error: $e');
      return null;
    }
  }

  static Future<bool> cancelIdentityVerification() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/identity/cancel');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ cancelIdentityVerification error: $e');
      return false;
    }
  }

  /// Submit identity verification
  static Future<bool> submitIdentityVerification({
    required String fullName,
    required String ninNumber,
    required File idPhoto,
    required File selfie,
    File? idDocument,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/identity');
      final headers = await _getHeaders();
      
      // Remove Content-Type from headers to let http package set it with boundary
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders.remove('Content-Type');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(requestHeaders);
      
      // Add form fields
      request.fields['fullName'] = fullName;
      request.fields['ninNumber'] = ninNumber;
      
      // Add files
      final idPhotoBytes = await idPhoto.readAsBytes();
      final idPhotoMime = lookupMimeType(idPhoto.path) ?? 'image/jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'idPhoto',
          idPhotoBytes,
          filename: path.basename(idPhoto.path),
          contentType: MediaType.parse(idPhotoMime),
        ),
      );
      
      final selfieBytes = await selfie.readAsBytes();
      final selfieMime = lookupMimeType(selfie.path) ?? 'image/jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'selfie',
          selfieBytes,
          filename: path.basename(selfie.path),
          contentType: MediaType.parse(selfieMime),
        ),
      );

      // Add optional ID document (PDF/DOC)
      if (idDocument != null) {
        final docBytes = await idDocument.readAsBytes();
        final docMime = lookupMimeType(idDocument.path) ?? 'application/pdf';
        request.files.add(
          http.MultipartFile.fromBytes(
            'idDocument',
            docBytes,
            filename: path.basename(idDocument.path),
            contentType: MediaType.parse(docMime),
          ),
        );
      }
      
      final response = await request.send().timeout(timeout);
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ submitIdentityVerification error: $e');
      return false;
    }
  }

  /// Get identity verification status
  static Future<Map<String, dynamic>?> getIdentityVerificationStatus() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/identity/status');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('⚠️ getIdentityVerificationStatus: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('⚠️ getIdentityVerificationStatus error: $e');
      return null;
    }
  }

  /// Submit property verification
  static Future<bool> submitPropertyVerification({
    required File propertyDocument,
    required List<File> propertyPhotos,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/property');
      final headers = await _getHeaders();
      
      // Remove Content-Type from headers to let http package set it with boundary
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders.remove('Content-Type');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(requestHeaders);
      
      // Add form fields
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (address != null) request.fields['address'] = address;
      
      // Add property document
      final docBytes = await propertyDocument.readAsBytes();
      final docMime = lookupMimeType(propertyDocument.path) ?? 'image/jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'propertyDocument',
          docBytes,
          filename: path.basename(propertyDocument.path),
          contentType: MediaType.parse(docMime),
        ),
      );
      
      // Add property photos
      for (int i = 0; i < propertyPhotos.length; i++) {
        final photoBytes = await propertyPhotos[i].readAsBytes();
        final photoMime = lookupMimeType(propertyPhotos[i].path) ?? 'image/jpeg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'propertyPhotos',
            photoBytes,
            filename: path.basename(propertyPhotos[i].path),
            contentType: MediaType.parse(photoMime),
          ),
        );
      }
      
      final response = await request.send().timeout(timeout);
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ submitPropertyVerification error: $e');
      return false;
    }
  }

  static Future<bool> cancelPropertyVerification() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/property/cancel');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ cancelPropertyVerification error: $e');
      return false;
    }
  }

  /// Cancel any active verification requests (identity/property)
  static Future<bool> cancelVerificationRequests() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/cancel');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ cancelVerificationRequests error: $e');
      return false;
    }
  }

  /// Get property verification status
  static Future<Map<String, dynamic>?> getPropertyVerificationStatus() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/property/status');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint('⚠️ getPropertyVerificationStatus: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('⚠️ getPropertyVerificationStatus error: $e');
      return null;
    }
  }

  // Admin methods
  /// Get pending identity verifications (admin only)
  static Future<List<dynamic>> getPendingIdentityVerifications() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/identity/pending');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      debugPrint('⚠️ getPendingIdentityVerifications: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('⚠️ getPendingIdentityVerifications error: $e');
      return [];
    }
  }

  /// Get pending property verifications (admin only)
  static Future<List<dynamic>> getPendingPropertyVerifications() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/property/pending');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      debugPrint('⚠️ getPendingPropertyVerifications: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('⚠️ getPendingPropertyVerifications error: $e');
      return [];
    }
  }

  /// Review identity verification (admin only)
  static Future<bool> reviewIdentityVerification({
    required String verificationId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/identity/$verificationId/review');
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'status': status,
          'adminNotes': adminNotes,
        }),
      ).timeout(timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ reviewIdentityVerification error: $e');
      return false;
    }
  }

  /// Review property verification (admin only)
  static Future<bool> reviewPropertyVerification({
    required String verificationId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/verification/property/$verificationId/review');
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'status': status,
          'adminNotes': adminNotes,
        }),
      ).timeout(timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ reviewPropertyVerification error: $e');
      return false;
    }
  }

  /// Get app policy/content data from backend
  static Future<Map<String, dynamic>?> getAppContent() async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix/content/app-settings');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('⚠️ getAppContent: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('⚠️ getAppContent error: $e');
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
