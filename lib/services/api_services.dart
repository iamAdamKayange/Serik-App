// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/model/rental_model.dart';

class ApiService {
  // 🔥 Change hii URL yako ya Ngrok
  static const String baseUrl =
      "https://stream-linguist-subzero.ngrok-free.dev/api";

  // Get auth token (utaweka baada ya login)
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
    debugPrint(
      '🔑 Auth token saved: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
    );
  }

  static String? getAuthToken() => _authToken;

  static Map<String, String> _getHeaders() {
    final headers = {"Content-Type": "application/json"};

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers["Authorization"] = "Bearer $_authToken";
      debugPrint('🔐 Adding Authorization header');
    } else {
      debugPrint('⚠️ No auth token available!');
    }

    return headers;
  }

  // ============ AUTH API ============

  // 🔥 REGISTER USER
  static Future<Map<String, dynamic>?> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      debugPrint('📡 POST $baseUrl/auth/register');
      debugPrint('📦 Request body: ${jsonEncode(userData)}');

      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": userData['firstName'],
          "lastName": userData['lastName'],
          "phone": userData['phone'],
          "email": userData['email'] ?? '',
          "password": userData['password'],
          "role": "normal",
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // If token is returned, save it
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data;
      } else {
        debugPrint("Failed to register: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error registering: $e");
      return null;
    }
  }

  // 🔥 LOGIN USER
  static Future<Map<String, dynamic>?> login(
    String phone,
    String password,
  ) async {
    try {
      debugPrint('📡 POST $baseUrl/auth/login');

      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "password": password}),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token if returned
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data;
      } else {
        debugPrint("Failed to login: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error logging in: $e");
      return null;
    }
  }

  // 🔥 SEND OTP
  static Future<Map<String, dynamic>?> sendOTP(String phone) async {
    try {
      debugPrint('📡 POST $baseUrl/auth/send-otp');
      debugPrint('📦 Phone: $phone');

      final response = await http.post(
        Uri.parse("$baseUrl/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Failed to send OTP: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error sending OTP: $e");
      return null;
    }
  }

  // 🔥 VERIFY OTP
  static Future<bool> verifyOTP(String phone, String otp) async {
    try {
      debugPrint('📡 POST $baseUrl/auth/verify-otp');
      debugPrint('📦 Phone: $phone, OTP: $otp');

      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "otp": otp}),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error verifying OTP: $e");
      return false;
    }
  }

  // ============ HOUSES API (RETURNS HouseData) ============
  static Future<List<HouseData>> getAllHouses() async {
    try {
      debugPrint('📡 GET $baseUrl/houses');
      final response = await http.get(
        Uri.parse("$baseUrl/houses"),
        headers: _getHeaders(),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HouseData.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load houses: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching houses: $e");
      return [];
    }
  }

  static Future<List<HouseData>> getUserHouses() async {
    try {
      debugPrint('📡 GET $baseUrl/houses/my');
      final response = await http.get(
        Uri.parse("$baseUrl/houses/my"),
        headers: _getHeaders(),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HouseData.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - Please login again');
        return [];
      } else {
        throw Exception("Failed to load user houses: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching user houses: $e");
      return [];
    }
  }

  // lib/services/api_service.dart

  static Future<HouseData?> addHouse(Map<String, dynamic> houseData) async {
    try {
      debugPrint('📡 POST $baseUrl/houses');

      // 🔥 Increase timeout for large base64 images
      final response = await http
          .post(
            Uri.parse("$baseUrl/houses"),
            headers: _getHeaders(),
            body: jsonEncode(houseData),
          )
          .timeout(const Duration(seconds: 60)); // 60 seconds timeout

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          return HouseData.fromJson(jsonDecode(response.body));
        } else {
          debugPrint(
            '⚠️ Response body is empty, creating house from request data',
          );
          return _createHouseFromRequestData(houseData);
        }
      } else {
        debugPrint("Failed to add house: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error adding house: $e");
      return null;
    }
  }

  static Future<bool> updateHouse(
    String houseId,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📡 PUT $baseUrl/houses/$houseId');
      final response = await http.put(
        Uri.parse("$baseUrl/houses/$houseId"),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      debugPrint('📡 Response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error updating house: $e");
      return false;
    }
  }

  static Future<bool> deleteHouse(String houseId) async {
    try {
      debugPrint('📡 DELETE $baseUrl/houses/$houseId');
      final response = await http.delete(
        Uri.parse("$baseUrl/houses/$houseId"),
        headers: _getHeaders(),
      );
      debugPrint('📡 Response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error deleting house: $e");
      return false;
    }
  }

  // ============ RENTAL SPOTS API (RETURNS RentalSpot) ============
  // 🔥 Get all houses as RentalSpots (kwa map page)
  static Future<List<RentalSpot>> getAllRentalSpots() async {
    try {
      final houses = await getAllHouses();
      return houses.map((house) => RentalSpot.fromHouseData(house)).toList();
    } catch (e) {
      debugPrint("❌ Error fetching rental spots: $e");
      return [];
    }
  }

  // 🔥 Get user houses as RentalSpots (kwa dashboard)
  static Future<List<RentalSpot>> getUserRentalSpots() async {
    try {
      final houses = await getUserHouses();
      return houses.map((house) => RentalSpot.fromHouseData(house)).toList();
    } catch (e) {
      debugPrint("❌ Error fetching user rental spots: $e");
      return [];
    }
  }

  // 🔥 Add house and return as RentalSpot
  static Future<RentalSpot?> addRentalSpot(
    Map<String, dynamic> houseData,
  ) async {
    try {
      final house = await addHouse(houseData);
      if (house != null) {
        return RentalSpot.fromHouseData(house);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error adding rental spot: $e");
      return null;
    }
  }

  // ============ HELPER METHODS ============

  // Helper method to create HouseData from request data when backend doesn't return data
  static HouseData _createHouseFromRequestData(Map<String, dynamic> houseData) {
    return HouseData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: houseData['name'] ?? '',
      status: houseData['status'] ?? 'Inapatikana',
      type: houseData['type'] ?? '',
      bedrooms: houseData['bedrooms'] ?? 0,
      description: houseData['description'] ?? '',
      firstName: houseData['firstName'] ?? '',
      lastName: houseData['lastName'] ?? '',
      phone: houseData['phone'] ?? '',
      rentPrice: (houseData['rentPrice'] ?? 0).toDouble(),
      location: houseData['location'] ?? '',
      images: houseData['images'] is List
          ? List<String>.from(houseData['images'])
          : [],
      latitude: houseData['latitude']?.toDouble(),
      longitude: houseData['longitude']?.toDouble(),
      address: houseData['address'] ?? '',
      region: houseData['region'] ?? '',
      district: houseData['district'] ?? '',
      division: houseData['division'] ?? '',
      ward: houseData['ward'] ?? '',
      village: houseData['village'] ?? '',
      street: houseData['street'] ?? '',
      depositAmount: houseData['depositAmount']?.toDouble(),
      waterIncluded: houseData['waterIncluded'] ?? false,
      electricityIncluded: houseData['electricityIncluded'] ?? false,
      internetIncluded: houseData['internetIncluded'] ?? false,
      nearbyAmenities: houseData['nearbyAmenities'] ?? '',
      createdAt: DateTime.now(),
    );
  }

  // Clear auth token (logout)
  static void clearAuthToken() {
    _authToken = null;
    debugPrint('🔑 Auth token cleared');
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    return _authToken != null && _authToken!.isNotEmpty;
  }
}
