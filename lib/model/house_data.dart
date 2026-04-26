// lib/model/house_data.dart
import 'dart:convert';

class HouseData {
  final String id;
  final String name;
  final String status;
  final String type;
  final int bedrooms;
  final String description;
  final String firstName;
  final String lastName;
  final String phone;
  final double rentPrice;
  final String location;
  final List<String> images;
  final double? latitude;
  final double? longitude;
  final String address;
  final String region;
  final String district;
  final String division;
  final String ward;
  final String village;
  final String street;
  final double? depositAmount;
  final bool waterIncluded;
  final bool electricityIncluded;
  final bool internetIncluded;
  final String nearbyAmenities;
  final DateTime createdAt;

  HouseData({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    required this.bedrooms,
    required this.description,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.rentPrice,
    required this.location,
    required this.images,
    this.latitude,
    this.longitude,
    required this.address,
    required this.region,
    required this.district,
    required this.division,
    required this.ward,
    required this.village,
    required this.street,
    this.depositAmount,
    required this.waterIncluded,
    required this.electricityIncluded,
    required this.internetIncluded,
    required this.nearbyAmenities,
    required this.createdAt,
  });

  // 🔥 HELPER: Parse images from different formats
  static List<String> _parseImages(dynamic imagesData) {
    if (imagesData == null) return [];

    // If it's already a List
    if (imagesData is List) {
      return imagesData.map((e) => e.toString()).toList();
    }

    // If it's a String
    if (imagesData is String) {
      // Check if it's an empty string
      if (imagesData.isEmpty) return [];

      // Check if it's a JSON array string
      if (imagesData.startsWith('[')) {
        try {
          final decoded = jsonDecode(imagesData);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // Fall through to pipe separator
        }
      }

      // Split by pipe separator (old format)
      if (imagesData.contains('||')) {
        return imagesData.split('||');
      }

      // Single image string
      return [imagesData];
    }

    return [];
  }

  // 🔥 FROM JSON (kupokea kutoka API)
  factory HouseData.fromJson(Map<String, dynamic> json) {
    return HouseData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'Inapatikana',
      type: json['type'] ?? 'Nyumba ya Kawaida',
      bedrooms: json['bedrooms'] ?? 1,
      description: json['description'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      rentPrice: (json['rent_price'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      images: _parseImages(json['images']), // 🔥 Use helper to parse images
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      division: json['division'] ?? '',
      ward: json['ward'] ?? '',
      village: json['village'] ?? '',
      street: json['street'] ?? '',
      depositAmount: json['deposit_amount']?.toDouble(),
      waterIncluded: json['water_included'] == true,
      electricityIncluded: json['electricity_included'] == true,
      internetIncluded: json['internet_included'] == true,
      nearbyAmenities: json['nearby_amenities'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // 🔥 TO JSON (kutuma kwa API)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'type': type,
      'bedrooms': bedrooms,
      'description': description,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'rentPrice': rentPrice,
      'location': location,
      'images': images, // Will be handled by backend
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'region': region,
      'district': district,
      'division': division,
      'ward': ward,
      'village': village,
      'street': street,
      'depositAmount': depositAmount,
      'waterIncluded': waterIncluded,
      'electricityIncluded': electricityIncluded,
      'internetIncluded': internetIncluded,
      'nearbyAmenities': nearbyAmenities,
    };
  }

  HouseData copyWith({
    String? id,
    String? name,
    String? status,
    String? type,
    int? bedrooms,
    String? description,
    String? firstName,
    String? lastName,
    String? phone,
    double? rentPrice,
    String? location,
    List<String>? images,
    double? latitude,
    double? longitude,
    String? address,
    String? region,
    String? district,
    String? division,
    String? ward,
    String? village,
    String? street,
    double? depositAmount,
    bool? waterIncluded,
    bool? electricityIncluded,
    bool? internetIncluded,
    String? nearbyAmenities,
    DateTime? createdAt,
  }) {
    return HouseData(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      bedrooms: bedrooms ?? this.bedrooms,
      description: description ?? this.description,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      rentPrice: rentPrice ?? this.rentPrice,
      location: location ?? this.location,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      region: region ?? this.region,
      district: district ?? this.district,
      division: division ?? this.division,
      ward: ward ?? this.ward,
      village: village ?? this.village,
      street: street ?? this.street,
      depositAmount: depositAmount ?? this.depositAmount,
      waterIncluded: waterIncluded ?? this.waterIncluded,
      electricityIncluded: electricityIncluded ?? this.electricityIncluded,
      internetIncluded: internetIncluded ?? this.internetIncluded,
      nearbyAmenities: nearbyAmenities ?? this.nearbyAmenities,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
