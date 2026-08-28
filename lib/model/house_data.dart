// lib/model/house_data.dart
import 'dart:convert';
import 'package:intl/intl.dart';

/// Aina za mpangilio wa nyumba
enum HouseLayoutType { selfContainer, shared, bedsitter, studio, flat }

/// Extension kwa ajili ya ku display majina ya layout types
extension HouseLayoutTypeExtension on HouseLayoutType {
  /// Jina la kuonyesha kwa UI
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

  /// Pata layout type kutoka string
  static HouseLayoutType fromString(String value) {
    final lower = value.toLowerCase().replaceAll('_', '');
    switch (lower) {
      case 'selfcontainer':
      case 'self_container':
        return HouseLayoutType.selfContainer;
      case 'shared':
        return HouseLayoutType.shared;
      case 'bedsitter':
        return HouseLayoutType.bedsitter;
      case 'studio':
        return HouseLayoutType.studio;
      case 'flat':
      case 'apartment':
        return HouseLayoutType.flat;
      default:
        return HouseLayoutType.selfContainer;
    }
  }

  /// Pata string ya layout type kwa backend
  String get backendValue {
    switch (this) {
      case HouseLayoutType.selfContainer:
        return 'self_container';
      case HouseLayoutType.shared:
        return 'shared';
      case HouseLayoutType.bedsitter:
        return 'bedsitter';
      case HouseLayoutType.studio:
        return 'studio';
      case HouseLayoutType.flat:
        return 'flat';
    }
  }
}

/// Data model kwa ajili ya nyumba
class HouseData {
  // ==================== BASIC INFO ====================
  final String id;
  final String name; // owner_name – jina la mwenye nyumba
  final String status;
  final String type;
  final int bedrooms;
  final String description;
  final String firstName; // brand_name – jina maarufu
  final String lastName; // house_number – namba ya nyumba
  final String phone;
  final String? landlordProfileImageUrl;
  final double rentPrice;
  final String location; // location_address

  // ==================== MEDIA ====================
  final List<String> images;
  final List<String> videos;
  final List<String> videoThumbnails;

  // ==================== LOCATION ====================
  final double? latitude;
  final double? longitude;
  final String address; // location_address (copy)
  final String region;
  final String district;
  final String division;
  final String ward;
  final String village;
  final String street;

  // ==================== PRICING ====================
  final double? depositAmount;

  // ==================== UTILITIES ====================
  final bool waterIncluded;
  final bool electricityIncluded;
  final bool internetIncluded;
  final String nearbyAmenities;

  // ==================== FEATURES ====================
  final bool hasCeiling;
  final bool hasAluminium;
  final bool hasCeilingBoard;
  final bool hasTiles;
  final bool hasFence;

  // ==================== LAYOUT ====================
  final HouseLayoutType layoutType;
  final bool hasPrivateBathroom;
  final bool hasPrivateToilet;
  final bool hasPrivateKitchen;
  final bool isSharedBathroom;
  final bool isSharedToilet;
  final bool isSharedKitchen;
  final int? numberOfSharedUnits;

  // ==================== TIMESTAMPS ====================
  final DateTime createdAt;

  // ==================== CONSTRUCTOR ====================

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
    this.landlordProfileImageUrl,
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

  // ==================== STATIC HELPERS ====================

  /// Salama kubadilisha value kuwa double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  /// Salama kubadilisha value kuwa int
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

  /// Salama kubadilisha value kuwa List<String>
  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
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

  // ==================== GETTERS ====================

  /// Pata vipengele vyote vya nyumba kama list
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

  /// Pata utilities zote kama list
  List<Map<String, dynamic>> get allUtilities => [
    {'name': 'Maji', 'key': 'waterIncluded', 'value': waterIncluded},
    {
      'name': 'Umeme',
      'key': 'electricityIncluded',
      'value': electricityIncluded,
    },
    {'name': 'Internet', 'key': 'internetIncluded', 'value': internetIncluded},
  ];

  /// Pata vipengele vyote vya layout kama list
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

  /// Pata features zote kwa category
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

  /// Angalia kama kuna feature yoyote
  bool get hasAnyFeature =>
      hasCeiling || hasAluminium || hasCeilingBoard || hasTiles || hasFence;

  /// Angalia kama kuna utility yoyote
  bool get hasAnyUtility =>
      waterIncluded || electricityIncluded || internetIncluded;

  /// Angalia kama ni self container
  bool get isSelfContainer =>
      hasPrivateBathroom && hasPrivateToilet && hasPrivateKitchen;

  /// Angalia kama ina vifaa vya kushiriki
  bool get isSharedFacility =>
      isSharedBathroom || isSharedToilet || isSharedKitchen;

  /// Angalia kama location ni valid
  bool hasValidLocation() => latitude != null && longitude != null;

  /// Pata bei formatted
  String get formattedPrice {
    final formatter = NumberFormat('#,###');
    return 'TZS ${formatter.format(rentPrice)}';
  }

  String get landlordDisplayName {
    return name.isNotEmpty ? name : firstName;
  }

  /// Pata deposit formatted
  String get formattedDeposit {
    if (depositAmount == null) return 'Haijabainishwa';
    final formatter = NumberFormat('#,###');
    return 'TZS ${formatter.format(depositAmount)}';
  }

  /// Pata features formatted
  String get formattedFeatures {
    List<String> features = [];
    if (hasCeiling) features.add('Fansi');
    if (hasAluminium) features.add('Aluminiam');
    if (hasCeilingBoard) features.add('Ceiling Board');
    if (hasTiles) features.add('Tiles');
    if (hasFence) features.add('Fence');
    return features.isEmpty ? 'Hakuna' : features.join(', ');
  }

  /// Pata utilities formatted
  String get formattedUtilities {
    List<String> utils = [];
    if (waterIncluded) utils.add('Maji');
    if (electricityIncluded) utils.add('Umeme');
    if (internetIncluded) utils.add('Internet');
    return utils.isEmpty ? 'Hakuna' : utils.join(', ');
  }

  // ==================== FROM JSON ====================

  /// Unda HouseData kutoka JSON (camelCase keys as returned by backend)
  factory HouseData.fromJson(Map<String, dynamic> json) {
    return HouseData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['owner_name'] ?? '',
      status: json['status'] ?? 'Inapatikana',
      type: json['type'] ?? 'Nyumba ya Kawaida',
      bedrooms: _toInt(json['bedrooms']),
      description: json['description'] ?? '',
      firstName: json['firstName'] ?? json['brand_name'] ?? '',
      lastName: json['lastName'] ?? json['house_number'] ?? '',
      phone: json['phone'] ?? '',
      landlordProfileImageUrl: json['landlord_profile_image_url']?.toString(),
      rentPrice: _toDouble(json['rentPrice'] ?? json['rent_price']),
      location:
          json['location'] ??
          json['locationAddress'] ??
          json['location_address'] ??
          '',
      images: _parseList(json['images']),
      videos: _parseList(json['videos']),
      videoThumbnails: _parseList(
        json['videoThumbnails'] ?? json['video_thumbnails'],
      ),
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null
          ? _toDouble(json['longitude'])
          : null,
      address:
          json['address'] ??
          json['locationAddress'] ??
          json['location_address'] ??
          '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      division: json['division'] ?? '',
      ward: json['ward'] ?? '',
      village: json['village'] ?? '',
      street: json['street'] ?? '',
      depositAmount: json['depositAmount'] != null
          ? _toDouble(json['depositAmount'])
          : (json['deposit_amount'] != null
                ? _toDouble(json['deposit_amount'])
                : null),
      waterIncluded:
          json['waterIncluded'] == true || json['water_included'] == true,
      electricityIncluded:
          json['electricityIncluded'] == true ||
          json['electricity_included'] == true,
      internetIncluded:
          json['internetIncluded'] == true || json['internet_included'] == true,
      nearbyAmenities:
          json['nearbyAmenities'] ?? json['nearby_amenities'] ?? '',
      hasCeiling: json['hasCeiling'] == true || json['has_ceiling'] == true,
      hasAluminium:
          json['hasAluminium'] == true || json['has_aluminium'] == true,
      hasCeilingBoard:
          json['hasCeilingBoard'] == true || json['has_ceiling_board'] == true,
      hasTiles: json['hasTiles'] == true || json['has_tiles'] == true,
      hasFence: json['hasFence'] == true || json['has_fence'] == true,
      layoutType: HouseLayoutTypeExtension.fromString(
        json['layoutType'] ?? json['layout_type'] ?? 'self_container',
      ),
      hasPrivateBathroom:
          json['hasPrivateBathroom'] ?? json['has_private_bathroom'] ?? true,
      hasPrivateToilet:
          json['hasPrivateToilet'] ?? json['has_private_toilet'] ?? true,
      hasPrivateKitchen:
          json['hasPrivateKitchen'] ?? json['has_private_kitchen'] ?? true,
      isSharedBathroom:
          json['isSharedBathroom'] ?? json['is_shared_bathroom'] ?? false,
      isSharedToilet:
          json['isSharedToilet'] ?? json['is_shared_toilet'] ?? false,
      isSharedKitchen:
          json['isSharedKitchen'] ?? json['is_shared_kitchen'] ?? false,
      numberOfSharedUnits: json['numberOfSharedUnits'] != null
          ? _toInt(json['numberOfSharedUnits'])
          : (json['number_of_shared_units'] != null
                ? _toInt(json['number_of_shared_units'])
                : null),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
    );
  }

  /// ✅ UNDA HouseData KUTOKA VIDEO FEED JSON (LIGHTWEIGHT)
  /// Inatumika kwa video feed - data ndogo tu
  factory HouseData.fromVideoFeedJson(Map<String, dynamic> json) {
    return HouseData(
      id: json['id']?.toString() ?? '',
      name: json['owner_name'] ?? json['name'] ?? '',
      status: 'Inapatikana',
      type: json['type'] ?? 'Nyumba ya Kawaida',
      bedrooms: 0,
      description: '',
      firstName: json['brand_name'] ?? json['firstName'] ?? '',
      lastName: json['house_number'] ?? json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      landlordProfileImageUrl: json['landlord_profile_image_url']?.toString(),
      rentPrice: _toDouble(json['rent_price'] ?? json['rentPrice']),
      location: json['location_address'] ?? json['location'] ?? '',
      images: [],
      videos: _parseList(json['videos']),
      videoThumbnails: _parseList(json['video_thumbnails']),
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null
          ? _toDouble(json['longitude'])
          : null,
      address: json['location_address'] ?? json['address'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      division: json['division'] ?? '',
      ward: json['ward'] ?? '',
      village: json['village'] ?? '',
      street: json['street'] ?? '',
      depositAmount: null,
      waterIncluded: false,
      electricityIncluded: false,
      internetIncluded: false,
      nearbyAmenities: '',
      hasCeiling: false,
      hasAluminium: false,
      hasCeilingBoard: false,
      hasTiles: false,
      hasFence: false,
      layoutType: HouseLayoutType.selfContainer,
      hasPrivateBathroom: true,
      hasPrivateToilet: true,
      hasPrivateKitchen: true,
      isSharedBathroom: false,
      isSharedToilet: false,
      isSharedKitchen: false,
      numberOfSharedUnits: null,
      createdAt: DateTime.now(),
    );
  }

  // ==================== TO JSON ====================

  /// Badilisha HouseData kuwa JSON (camelCase keys expected by backend)
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
      'locationAddress': location,
      'latitude': latitude,
      'longitude': longitude,
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
      'hasCeiling': hasCeiling,
      'hasAluminium': hasAluminium,
      'hasCeilingBoard': hasCeilingBoard,
      'hasTiles': hasTiles,
      'hasFence': hasFence,
      'layoutType': layoutType.backendValue,
      'hasPrivateBathroom': hasPrivateBathroom,
      'hasPrivateToilet': hasPrivateToilet,
      'hasPrivateKitchen': hasPrivateKitchen,
      'isSharedBathroom': isSharedBathroom,
      'isSharedToilet': isSharedToilet,
      'isSharedKitchen': isSharedKitchen,
      'numberOfSharedUnits': numberOfSharedUnits,
      'imageUrls': images,
      'videoUrls': videos,
      'videoThumbnails': videoThumbnails,
    };
  }

  // ==================== COPY WITH ====================

  /// Unda copy ya HouseData na mabadiliko
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

  @override
  String toString() {
    return 'HouseData(id: $id, name: $name, price: $formattedPrice)';
  }
}
