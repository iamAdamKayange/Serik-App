import 'dart:convert';
import 'package:intl/intl.dart';

enum HouseLayoutType { selfContainer, shared, bedsitter, studio, flat }

extension HouseLayoutTypeExtension on HouseLayoutType {
  String get displayName {
    switch (this) {
      case HouseLayoutType.selfContainer:
        return 'Self Container';
      case HouseLayoutType.shared:
        return 'Shared (Single Room)';
      case HouseLayoutType.bedsitter:
        return 'Bedsitter';
      case HouseLayoutType.studio:
        return 'Studio Apartment';
      case HouseLayoutType.flat:
        return 'Flat/Apartment';
    }
  }
}

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
  final List<String> videos;
  final List<String> videoThumbnails;
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

  final bool hasCeiling;
  final bool hasAluminium;
  final bool hasCeilingBoard;
  final bool hasTiles;
  final bool hasFence;

  final HouseLayoutType layoutType;
  final bool hasPrivateBathroom;
  final bool hasPrivateToilet;
  final bool hasPrivateKitchen;
  final bool isSharedBathroom;
  final bool isSharedToilet;
  final bool isSharedKitchen;
  final int? numberOfSharedUnits;

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
    required this.videos,
    required this.videoThumbnails,
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
    this.waterIncluded = false,
    this.electricityIncluded = false,
    this.internetIncluded = false,
    this.nearbyAmenities = '',
    this.hasCeiling = false,
    this.hasAluminium = false,
    this.hasCeilingBoard = false,
    this.hasTiles = false,
    this.hasFence = false,
    this.layoutType = HouseLayoutType.selfContainer,
    this.hasPrivateBathroom = true,
    this.hasPrivateToilet = true,
    this.hasPrivateKitchen = true,
    this.isSharedBathroom = false,
    this.isSharedToilet = false,
    this.isSharedKitchen = false,
    this.numberOfSharedUnits,
    required this.createdAt,
  });

  // Helper to parse any value to double safely (supports String, int, double)
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove any non‑numeric characters except dot and minus
      final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // Helper to parse any value to int safely
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9-]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  // Helper to parse array from JSON
  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    if (data is String) {
      if (data.isEmpty) return [];
      if (data.startsWith('[')) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      if (data.contains('||')) return data.split('||');
      return [data];
    }
    return [];
  }

  // Getters
  List<Map<String, dynamic>> get allToggleFeatures => [
    {'name': 'Fansi (Ceiling)', 'key': 'hasCeiling', 'value': hasCeiling},
    {'name': 'Aluminiam Indoor', 'key': 'hasAluminium', 'value': hasAluminium},
    {
      'name': 'Ceiling Board',
      'key': 'hasCeilingBoard',
      'value': hasCeilingBoard,
    },
    {'name': 'Tiles', 'key': 'hasTiles', 'value': hasTiles},
    {'name': 'Fence / Uzio', 'key': 'hasFence', 'value': hasFence},
  ];

  List<Map<String, dynamic>> get allUtilities => [
    {'name': 'Maji', 'key': 'waterIncluded', 'value': waterIncluded},
    {
      'name': 'Umeme',
      'key': 'electricityIncluded',
      'value': electricityIncluded,
    },
    {'name': 'Internet', 'key': 'internetIncluded', 'value': internetIncluded},
  ];

  List<Map<String, dynamic>> get allLayoutFeatures => [
    {
      'name': 'Bafu ya ndani',
      'key': 'hasPrivateBathroom',
      'value': hasPrivateBathroom,
    },
    {
      'name': 'Choo cha ndani',
      'key': 'hasPrivateToilet',
      'value': hasPrivateToilet,
    },
    {
      'name': 'Jikoni ya ndani',
      'key': 'hasPrivateKitchen',
      'value': hasPrivateKitchen,
    },
    {
      'name': 'Bafu ya kushiriki',
      'key': 'isSharedBathroom',
      'value': isSharedBathroom,
    },
    {
      'name': 'Choo cha kushiriki',
      'key': 'isSharedToilet',
      'value': isSharedToilet,
    },
    {
      'name': 'Jiko la kushiriki',
      'key': 'isSharedKitchen',
      'value': isSharedKitchen,
    },
  ];

  List<Map<String, dynamic>> getAllFeaturesForUI(String category) {
    switch (category) {
      case 'nyumba':
        return allToggleFeatures;
      case 'utilities':
        return allUtilities;
      case 'layout':
        return allLayoutFeatures;
      default:
        return [];
    }
  }

  bool get hasAnyFeature =>
      hasCeiling || hasAluminium || hasCeilingBoard || hasTiles || hasFence;
  bool get hasAnyUtility =>
      waterIncluded || electricityIncluded || internetIncluded;
  bool get isSelfContainer =>
      hasPrivateBathroom && hasPrivateToilet && hasPrivateKitchen;
  bool get isSharedFacility =>
      isSharedBathroom || isSharedToilet || isSharedKitchen;

  bool hasValidLocation() => latitude != null && longitude != null;

  String get formattedPrice {
    final formatter = NumberFormat('#,###');
    return 'TZS ${formatter.format(rentPrice)}';
  }

  String get formattedDeposit {
    if (depositAmount == null) return 'Haijabainishwa';
    final formatter = NumberFormat('#,###');
    return 'TZS ${formatter.format(depositAmount)}';
  }

  String get formattedFeatures {
    List<String> features = [];
    if (hasCeiling) features.add('Fansi');
    if (hasAluminium) features.add('Aluminiam');
    if (hasCeilingBoard) features.add('Ceiling Board');
    if (hasTiles) features.add('Tiles');
    if (hasFence) features.add('Fence');
    return features.isEmpty ? 'Hakuna' : features.join(', ');
  }

  String get formattedUtilities {
    List<String> utils = [];
    if (waterIncluded) utils.add('Maji');
    if (electricityIncluded) utils.add('Umeme');
    if (internetIncluded) utils.add('Internet');
    return utils.isEmpty ? 'Hakuna' : utils.join(', ');
  }

  // FROM JSON (with safe numeric conversion)
  factory HouseData.fromJson(Map<String, dynamic> json) {
    HouseLayoutType parsedLayoutType = HouseLayoutType.selfContainer;
    if (json['layout_type'] != null) {
      switch (json['layout_type'].toString().toLowerCase()) {
        case 'self_container':
        case 'selfcontainer':
          parsedLayoutType = HouseLayoutType.selfContainer;
          break;
        case 'shared':
          parsedLayoutType = HouseLayoutType.shared;
          break;
        case 'bedsitter':
          parsedLayoutType = HouseLayoutType.bedsitter;
          break;
        case 'studio':
          parsedLayoutType = HouseLayoutType.studio;
          break;
        case 'flat':
        case 'apartment':
          parsedLayoutType = HouseLayoutType.flat;
          break;
      }
    }

    return HouseData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'Inapatikana',
      type: json['type'] ?? 'Nyumba ya Kawaida',
      bedrooms: _toInt(json['bedrooms']),
      description: json['description'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      rentPrice: _toDouble(json['rent_price']),
      location: json['location'] ?? '',
      images: _parseList(json['images']),
      videos: _parseList(json['videos']),
      videoThumbnails: _parseList(json['video_thumbnails']),
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null
          ? _toDouble(json['longitude'])
          : null,
      address: json['address'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      division: json['division'] ?? '',
      ward: json['ward'] ?? '',
      village: json['village'] ?? '',
      street: json['street'] ?? '',
      depositAmount: json['deposit_amount'] != null
          ? _toDouble(json['deposit_amount'])
          : null,
      waterIncluded: json['water_included'] == true,
      electricityIncluded: json['electricity_included'] == true,
      internetIncluded: json['internet_included'] == true,
      nearbyAmenities: json['nearby_amenities'] ?? '',
      hasCeiling: json['has_ceiling'] == true,
      hasAluminium: json['has_aluminium'] == true,
      hasCeilingBoard: json['has_ceiling_board'] == true,
      hasTiles: json['has_tiles'] == true,
      hasFence: json['has_fence'] == true,
      layoutType: parsedLayoutType,
      hasPrivateBathroom: json['has_private_bathroom'] ?? true,
      hasPrivateToilet: json['has_private_toilet'] ?? true,
      hasPrivateKitchen: json['has_private_kitchen'] ?? true,
      isSharedBathroom: json['is_shared_bathroom'] ?? false,
      isSharedToilet: json['is_shared_toilet'] ?? false,
      isSharedKitchen: json['is_shared_kitchen'] ?? false,
      numberOfSharedUnits: json['number_of_shared_units'] != null
          ? _toInt(json['number_of_shared_units'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // TO JSON
  Map<String, dynamic> toJson() {
    String layoutTypeString;
    switch (layoutType) {
      case HouseLayoutType.selfContainer:
        layoutTypeString = 'self_container';
        break;
      case HouseLayoutType.shared:
        layoutTypeString = 'shared';
        break;
      case HouseLayoutType.bedsitter:
        layoutTypeString = 'bedsitter';
        break;
      case HouseLayoutType.studio:
        layoutTypeString = 'studio';
        break;
      case HouseLayoutType.flat:
        layoutTypeString = 'flat';
        break;
    }

    return {
      'name': name,
      'status': status,
      'type': type,
      'bedrooms': bedrooms,
      'description': description,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'rent_price': rentPrice,
      'location': location,
      'images': images,
      'videos': videos,
      'video_thumbnails': videoThumbnails,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'region': region,
      'district': district,
      'division': division,
      'ward': ward,
      'village': village,
      'street': street,
      'deposit_amount': depositAmount,
      'water_included': waterIncluded,
      'electricity_included': electricityIncluded,
      'internet_included': internetIncluded,
      'nearby_amenities': nearbyAmenities,
      'has_ceiling': hasCeiling,
      'has_aluminium': hasAluminium,
      'has_ceiling_board': hasCeilingBoard,
      'has_tiles': hasTiles,
      'has_fence': hasFence,
      'layout_type': layoutTypeString,
      'has_private_bathroom': hasPrivateBathroom,
      'has_private_toilet': hasPrivateToilet,
      'has_private_kitchen': hasPrivateKitchen,
      'is_shared_bathroom': isSharedBathroom,
      'is_shared_toilet': isSharedToilet,
      'is_shared_kitchen': isSharedKitchen,
      'number_of_shared_units': numberOfSharedUnits,
    };
  }

  // COPYWITH
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
    List<String>? videos,
    List<String>? videoThumbnails,
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
    bool? hasCeiling,
    bool? hasAluminium,
    bool? hasCeilingBoard,
    bool? hasTiles,
    bool? hasFence,
    HouseLayoutType? layoutType,
    bool? hasPrivateBathroom,
    bool? hasPrivateToilet,
    bool? hasPrivateKitchen,
    bool? isSharedBathroom,
    bool? isSharedToilet,
    bool? isSharedKitchen,
    int? numberOfSharedUnits,
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
      videos: videos ?? this.videos,
      videoThumbnails: videoThumbnails ?? this.videoThumbnails,
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
      hasCeiling: hasCeiling ?? this.hasCeiling,
      hasAluminium: hasAluminium ?? this.hasAluminium,
      hasCeilingBoard: hasCeilingBoard ?? this.hasCeilingBoard,
      hasTiles: hasTiles ?? this.hasTiles,
      hasFence: hasFence ?? this.hasFence,
      layoutType: layoutType ?? this.layoutType,
      hasPrivateBathroom: hasPrivateBathroom ?? this.hasPrivateBathroom,
      hasPrivateToilet: hasPrivateToilet ?? this.hasPrivateToilet,
      hasPrivateKitchen: hasPrivateKitchen ?? this.hasPrivateKitchen,
      isSharedBathroom: isSharedBathroom ?? this.isSharedBathroom,
      isSharedToilet: isSharedToilet ?? this.isSharedToilet,
      isSharedKitchen: isSharedKitchen ?? this.isSharedKitchen,
      numberOfSharedUnits: numberOfSharedUnits ?? this.numberOfSharedUnits,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
