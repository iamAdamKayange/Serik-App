// lib/model/rental_model.dart
import 'package:intl/intl.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/model/house_data.dart' as house;

class RentalSpot {
  final String id;
  final String name;
  final String status;
  final String type;
  final int bedrooms;
  final String description;

  final String firstName;
  final String lastName;
  final String phone;
  final String? altPhone;

  final double rentPrice;
  final String formattedPrice;
  final double? depositAmount;
  final bool waterIncluded;
  final bool electricityIncluded;
  final bool internetIncluded;
  final String? nearbyAmenities;

  final String location;
  final String address;
  final double latitude;
  final double longitude;

  final String region;
  final String district;
  final String division;
  final String ward;
  final String village;
  final String street;

  final bool hasCeiling;
  final bool hasAluminium;
  final bool hasCeilingBoard;
  final bool hasTiles;
  final bool hasFence;

  final house.HouseLayoutType layoutType;
  final bool hasPrivateBathroom;
  final bool hasPrivateToilet;
  final bool hasPrivateKitchen;
  final bool isSharedBathroom;
  final bool isSharedToilet;
  final bool isSharedKitchen;
  final int? numberOfSharedUnits;

  final List<String> images;
  final List<String> videos;
  final List<String> videoThumbnails;

  final DateTime dateAdded;

  String get brandName => firstName;
  String get ownerName => name;
  String get houseNumber => lastName;

  // ==================== CONSTRUCTORS ====================

  RentalSpot({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    required this.bedrooms,
    required this.description,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.altPhone,
    required this.rentPrice,
    required this.location,
    required this.images,
    required this.videos,
    required this.videoThumbnails,
    required this.dateAdded,
    this.depositAmount,
    this.waterIncluded = false,
    this.electricityIncluded = false,
    this.internetIncluded = false,
    this.nearbyAmenities,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
    this.region = '',
    this.district = '',
    this.division = '',
    this.ward = '',
    this.village = '',
    this.street = '',
    this.hasCeiling = false,
    this.hasAluminium = false,
    this.hasCeilingBoard = false,
    this.hasTiles = false,
    this.hasFence = false,
    this.layoutType = house.HouseLayoutType.selfContainer,
    this.hasPrivateBathroom = true,
    this.hasPrivateToilet = true,
    this.hasPrivateKitchen = true,
    this.isSharedBathroom = false,
    this.isSharedToilet = false,
    this.isSharedKitchen = false,
    this.numberOfSharedUnits,
  }) : formattedPrice = _formatPrice(rentPrice);

  // ✅ CONSTRUCTOR KWA VIDEO FEED
  RentalSpot.forVideoFeed({
    required String id,
    required String brandName,
    required double rentPrice,
    required String location,
    required String region,
    required String district,
    required String ward,
    required String street,
    double? latitude,
    double? longitude,
    List<String>? videos,
    List<String>? videoThumbnails,
  }) : id = id,
       firstName = brandName,
       name = brandName,
       status = 'Inapatikana',
       type = 'Nyumba ya Kawaida',
       bedrooms = 0,
       description = '',
       lastName = '',
       phone = '',
       altPhone = null,
       rentPrice = rentPrice,
       location = location,
       images = [],
       videos = videos ?? [],
       videoThumbnails = videoThumbnails ?? [],
       dateAdded = DateTime.now(),
       depositAmount = null,
       waterIncluded = false,
       electricityIncluded = false,
       internetIncluded = false,
       nearbyAmenities = null,
       latitude = latitude ?? 0.0,
       longitude = longitude ?? 0.0,
       address = location,
       region = region,
       district = district,
       division = '',
       ward = ward,
       village = '',
       street = street,
       hasCeiling = false,
       hasAluminium = false,
       hasCeilingBoard = false,
       hasTiles = false,
       hasFence = false,
       layoutType = house.HouseLayoutType.selfContainer,
       hasPrivateBathroom = true,
       hasPrivateToilet = true,
       hasPrivateKitchen = true,
       isSharedBathroom = false,
       isSharedToilet = false,
       isSharedKitchen = false,
       numberOfSharedUnits = null,
       formattedPrice = _formatPrice(rentPrice);

  static String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  // ==================== FACTORIES ====================

  factory RentalSpot.fromHouseData(HouseData house) {
    return RentalSpot(
      id: house.id,
      name: house.name,
      status: house.status,
      type: house.type,
      bedrooms: house.bedrooms,
      description: house.description,
      firstName: house.firstName,
      lastName: house.lastName,
      phone: house.phone,
      altPhone: null,
      rentPrice: house.rentPrice,
      location: house.location,
      images: house.images,
      videos: house.videos,
      videoThumbnails: house.videoThumbnails,
      dateAdded: house.createdAt,
      depositAmount: house.depositAmount,
      waterIncluded: house.waterIncluded,
      electricityIncluded: house.electricityIncluded,
      internetIncluded: house.internetIncluded,
      nearbyAmenities: house.nearbyAmenities,
      latitude: house.latitude ?? 0.0,
      longitude: house.longitude ?? 0.0,
      address: house.address,
      region: house.region,
      district: house.district,
      division: house.division,
      ward: house.ward,
      village: house.village,
      street: house.street,
      hasCeiling: house.hasCeiling,
      hasAluminium: house.hasAluminium,
      hasCeilingBoard: house.hasCeilingBoard,
      hasTiles: house.hasTiles,
      hasFence: house.hasFence,
      layoutType: house.layoutType,
      hasPrivateBathroom: house.hasPrivateBathroom,
      hasPrivateToilet: house.hasPrivateToilet,
      hasPrivateKitchen: house.hasPrivateKitchen,
      isSharedBathroom: house.isSharedBathroom,
      isSharedToilet: house.isSharedToilet,
      isSharedKitchen: house.isSharedKitchen,
      numberOfSharedUnits: house.numberOfSharedUnits,
    );
  }

  /// ✅ Factory kutoka JSON ya video feed - SAFE PARSING
  factory RentalSpot.fromVideoFeedJson(Map<String, dynamic> json) {
    // Safe parser for price (handles String or num)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    // Safe parser for lat/lng (handles String or num)
    double parseLatLng(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    return RentalSpot.forVideoFeed(
      id: json['id']?.toString() ?? '',
      brandName: json['brand_name'] ?? json['firstName'] ?? 'Nyumba',
      rentPrice: parsePrice(json['rent_price'] ?? json['rentPrice']),
      location: json['location_address'] ?? json['location'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      ward: json['ward'] ?? '',
      street: json['street'] ?? '',
      latitude: parseLatLng(json['latitude']),
      longitude: parseLatLng(json['longitude']),
      videos: (json['videos'] as List?)?.cast<String>() ?? [],
      videoThumbnails:
          (json['video_thumbnails'] as List?)?.cast<String>() ?? [],
    );
  }

  // ==================== HELPER METHODS ====================

  String getFullSwahiliAddress() {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add("Mtaa: $street");
    if (village.isNotEmpty) parts.add("Kijiji: $village");
    if (ward.isNotEmpty) parts.add("Kata: $ward");
    if (division.isNotEmpty && division != 'Hakuna Tarafa') {
      parts.add("Tarafa: $division");
    }
    if (district.isNotEmpty) parts.add("Wilaya: $district");
    if (region.isNotEmpty) parts.add("Mkoa: $region");
    return parts.isNotEmpty
        ? parts.join(", ")
        : (address.isNotEmpty ? address : location);
  }

  String getShortAddress() {
    if (street.isNotEmpty && ward.isNotEmpty) {
      return "$street, $ward";
    } else if (ward.isNotEmpty && district.isNotEmpty) {
      return "$ward, $district";
    } else if (district.isNotEmpty) {
      return district;
    } else if (address.isNotEmpty) {
      return address;
    }
    return location;
  }

  String getFormattedAddress() {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (ward.isNotEmpty) parts.add(ward);
    if (district.isNotEmpty) parts.add(district);
    if (region.isNotEmpty) parts.add(region);
    return parts.isEmpty ? location : parts.join(', ');
  }

  String getPriceDetails() {
    String details = "💰 Kodi: $formattedPrice kwa mwezi";
    if (hasDeposit()) {
      final depositFormatted = NumberFormat.currency(
        locale: 'sw_TZ',
        symbol: 'TZS ',
        decimalDigits: 0,
      ).format(depositAmount!);
      details += "\n🏦 Deposit: $depositFormatted";
    }
    List<String> included = [];
    if (waterIncluded) included.add("💧 Maji");
    if (electricityIncluded) included.add("⚡ Umeme");
    if (internetIncluded) included.add("🌐 Internet");
    if (included.isNotEmpty) {
      details += "\n✅ Yamo katika kodi: ${included.join(", ")}";
    }
    return details;
  }

  List<String> getIncludedAmenities() {
    List<String> amenities = [];
    if (waterIncluded) amenities.add("Maji");
    if (electricityIncluded) amenities.add("Umeme");
    if (internetIncluded) amenities.add("Internet");
    return amenities;
  }

  List<String> getNearbyAmenitiesList() {
    if (nearbyAmenities == null || nearbyAmenities!.isEmpty) return [];
    return nearbyAmenities!.split(',').map((e) => e.trim()).toList();
  }

  List<String> getAllHouseFeatures() {
    List<String> features = [];
    if (hasCeiling) features.add("Fansi");
    if (hasAluminium) features.add("Aluminiam");
    if (hasCeilingBoard) features.add("Ceiling Board");
    if (hasTiles) features.add("Tiles");
    if (hasFence) features.add("Fence / Uzio");
    return features;
  }

  bool get hasAnyFeature =>
      hasCeiling || hasAluminium || hasCeilingBoard || hasTiles || hasFence;

  String get formattedFeatures {
    List<String> features = getAllHouseFeatures();
    return features.isEmpty ? "Hakuna vipengele maalum" : features.join(" • ");
  }

  int get featuresCount {
    int count = 0;
    if (hasCeiling) count++;
    if (hasAluminium) count++;
    if (hasCeilingBoard) count++;
    if (hasTiles) count++;
    if (hasFence) count++;
    return count;
  }

  bool get isSelfContainer =>
      layoutType == house.HouseLayoutType.selfContainer ||
      (hasPrivateBathroom && hasPrivateToilet && hasPrivateKitchen);

  bool get isSharedFacility =>
      layoutType == house.HouseLayoutType.shared ||
      isSharedBathroom ||
      isSharedToilet ||
      isSharedKitchen;

  String get layoutDescription {
    switch (layoutType) {
      case house.HouseLayoutType.selfContainer:
        return 'Self container: Vyumba vyote (chumba, bafu, choo, jikoni) viko ndani ya nyumba yako. Hakuna kushirikiana na mtu mwingine.';
      case house.HouseLayoutType.shared:
        if (numberOfSharedUnits != null) {
          return 'Single room: Unashirikisha bafu, choo, na jikoni na wapangaji wengine ($numberOfSharedUnits).';
        }
        return 'Single room: Unashirikisha bafu, choo, na jikoni na wapangaji wengine.';
      case house.HouseLayoutType.bedsitter:
        return 'Bedsitter: Chumba kimoja chenye bafu na choo yake private. Jikoni inaweza kuwa ndani au nje.';
      case house.HouseLayoutType.studio:
        return 'Studio: Chumba kikubwa chenye jikoni ndogo na bafu private.';
      case house.HouseLayoutType.flat:
        return 'Flat/Apartment: Self contained kwenye ghorofa, kwa kawaida na vyumba zaidi ya kimoja.';
    }
  }

  String get facilitiesStatus {
    List<String> facilities = [];
    if (hasPrivateBathroom) {
      facilities.add('Bafu private');
    } else if (isSharedBathroom) {
      facilities.add('Bafu shared');
    }
    if (hasPrivateToilet) {
      facilities.add('Choo private');
    } else if (isSharedToilet) {
      facilities.add('Choo shared');
    }
    if (hasPrivateKitchen) {
      facilities.add('Jikoni private');
    } else if (isSharedKitchen) {
      facilities.add('Jikoni shared');
    }
    return facilities.isEmpty
        ? 'Taarifa za vifaa hazijabainishwa'
        : facilities.join(', ');
  }

  bool hasDeposit() => depositAmount != null && depositAmount! > 0;
  bool hasValidLocation() => latitude != 0.0 && longitude != 0.0;
  bool hasCompleteAddress() =>
      region.isNotEmpty &&
      district.isNotEmpty &&
      ward.isNotEmpty &&
      street.isNotEmpty;

  String getMapUrl() =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String getDirectionsUrl() =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';

  String getWhatsAppShareText() {
    String featuresText = getAllHouseFeatures().isNotEmpty
        ? "\n✨ *Vipengele:* ${getAllHouseFeatures().join(", ")}"
        : "";
    return "🏠 *${brandName.toUpperCase()}*\n"
        "🔢 *Namba ya Nyumba:* ${houseNumber.isNotEmpty ? houseNumber : "Hajabainishwa"}\n"
        "📍 *Anwani:* ${getFormattedAddress()}\n"
        "💰 *Bei:* $formattedPrice kwa mwezi\n"
        "🛏️ *Vyumba vya kulala:* $bedrooms\n"
        "🏷️ *Aina:* $type\n"
        "📋 *Hali:* $status\n"
        "$featuresText\n"
        "\n📞 *Mwenye Nyumba:* $ownerName\n"
        "📞 *Simu:* $phone\n"
        "\n🔗 Tazama nyumba hii kwenye App yetu!";
  }

  String getFullOwnerName() => ownerName;
  String getShortDescription() => description.length > 100
      ? "${description.substring(0, 100)}..."
      : description;
  bool hasImages() => images.isNotEmpty;
  String? getFirstImage() => images.isNotEmpty ? images.first : null;
  bool get hasAnyUtility =>
      waterIncluded || electricityIncluded || internetIncluded;

  String get formattedUtilities {
    List<String> utils = [];
    if (waterIncluded) utils.add("Maji");
    if (electricityIncluded) utils.add("Umeme");
    if (internetIncluded) utils.add("Internet");
    return utils.isEmpty ? "Hakuna" : utils.join(", ");
  }

  RentalSpot copyWith({
    String? id,
    String? name,
    String? status,
    String? type,
    int? bedrooms,
    String? description,
    String? firstName,
    String? lastName,
    String? phone,
    String? altPhone,
    double? rentPrice,
    String? location,
    List<String>? images,
    List<String>? videos,
    List<String>? videoThumbnails,
    DateTime? dateAdded,
    double? depositAmount,
    bool? waterIncluded,
    bool? electricityIncluded,
    bool? internetIncluded,
    String? nearbyAmenities,
    double? latitude,
    double? longitude,
    String? address,
    String? region,
    String? district,
    String? division,
    String? ward,
    String? village,
    String? street,
    bool? hasCeiling,
    bool? hasAluminium,
    bool? hasCeilingBoard,
    bool? hasTiles,
    bool? hasFence,
    house.HouseLayoutType? layoutType,
    bool? hasPrivateBathroom,
    bool? hasPrivateToilet,
    bool? hasPrivateKitchen,
    bool? isSharedBathroom,
    bool? isSharedToilet,
    bool? isSharedKitchen,
    int? numberOfSharedUnits,
  }) {
    return RentalSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      bedrooms: bedrooms ?? this.bedrooms,
      description: description ?? this.description,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      rentPrice: rentPrice ?? this.rentPrice,
      location: location ?? this.location,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      videoThumbnails: videoThumbnails ?? this.videoThumbnails,
      dateAdded: dateAdded ?? this.dateAdded,
      depositAmount: depositAmount ?? this.depositAmount,
      waterIncluded: waterIncluded ?? this.waterIncluded,
      electricityIncluded: electricityIncluded ?? this.electricityIncluded,
      internetIncluded: internetIncluded ?? this.internetIncluded,
      nearbyAmenities: nearbyAmenities ?? this.nearbyAmenities,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      region: region ?? this.region,
      district: district ?? this.district,
      division: division ?? this.division,
      ward: ward ?? this.ward,
      village: village ?? this.village,
      street: street ?? this.street,
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
    );
  }

  @override
  String toString() =>
      'RentalSpot(brandName: $brandName, price: $formattedPrice, location: ${getShortAddress()})';
}
