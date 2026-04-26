// lib/model/rental_model.dart
import 'package:intl/intl.dart';
import 'package:serkapp/model/house_data.dart';

class RentalSpot {
  // ========== TAARIFA ZA MSINGI (BASIC INFO) ==========
  final String id;
  final String name;
  final String status;
  final String type;
  final int bedrooms;
  final String description;

  // ========== TAARIFA ZA MWENYE NYUMBA (OWNER INFO) ==========
  final String firstName;
  final String lastName;
  final String phone;
  final String? altPhone;

  // ========== BEI NA MALIPO (PRICE & PAYMENTS) ==========
  final double rentPrice;
  final String formattedPrice;
  final double? depositAmount;
  final bool waterIncluded;
  final bool electricityIncluded;
  final bool internetIncluded;
  final String? nearbyAmenities;

  // ========== ENEO NA RAMANI (LOCATION & MAP) ==========
  final String location;
  final String address;
  final double latitude;
  final double longitude;

  // ========== HIERARCHY YA ENEO KWA KISWAHILI ==========
  final String region;
  final String district;
  final String division;
  final String ward;
  final String village;
  final String street;

  // ========== PICHA (IMAGES) ==========
  final List<String> images;

  // ========== TARIKH (DATE) ==========
  final DateTime dateAdded;

  // ========== CONSTRUCTOR ==========
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
  }) : formattedPrice = _formatPrice(rentPrice);

  // ========== HELPER: FORMAT PRICE ==========
  static String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  // ========== 🆕 FACTORY CONSTRUCTOR KUTOKA HouseData ==========
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
      dateAdded: house.createdAt, // 🔥 FIX: Use createdAt instead of dateAdded
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
    );
  }

  // ========== HELPER METHOD 1: ANWANI KAMILI KWA KISWAHILI ==========
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

  // ========== HELPER METHOD 2: ANWANI FUPI KWA MAP ==========
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

  // ========== HELPER METHOD 3: MAELEZO KAMILI YA BEI ==========
  String getPriceDetails() {
    String details = "💰 Kodi: $formattedPrice kwa mwezi";

    if (depositAmount != null && depositAmount! > 0) {
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

  // ========== HELPER METHOD 4: VITU VILIVYOJUMUISHWA ==========
  List<String> getIncludedAmenities() {
    List<String> amenities = [];
    if (waterIncluded) amenities.add("Maji");
    if (electricityIncluded) amenities.add("Umeme");
    if (internetIncluded) amenities.add("Internet");
    return amenities;
  }

  // ========== HELPER METHOD 5: VITU VILIVYO KARIBU ==========
  List<String> getNearbyAmenitiesList() {
    if (nearbyAmenities == null || nearbyAmenities!.isEmpty) {
      return [];
    }
    return nearbyAmenities!.split(',').map((e) => e.trim()).toList();
  }

  // ========== HELPER METHOD 6: ANGALIA KAMA DEPOSIT IPO ==========
  bool hasDeposit() {
    return depositAmount != null && depositAmount! > 0;
  }

  // ========== HELPER METHOD 7: ANGALIA KAMA ENEO LA RAMANI LIPO ==========
  bool hasValidLocation() {
    return latitude != 0.0 && longitude != 0.0;
  }

  // ========== HELPER METHOD 8: ANGALIA KAMA ANWANI IMEKAMILIKA ==========
  bool hasCompleteAddress() {
    return region.isNotEmpty &&
        district.isNotEmpty &&
        ward.isNotEmpty &&
        street.isNotEmpty;
  }

  // ========== HELPER METHOD 9: URL YA RAMANI ==========
  String getMapUrl() {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  // ========== HELPER METHOD 10: URL YA DIRECTIONS ==========
  String getDirectionsUrl() {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }

  // ========== HELPER METHOD 11: TEXT YA KUSAMBAZA KWA WHATSAPP ==========
  String getWhatsAppShareText() {
    return "🏠 *${name.toUpperCase()}*\n\n"
        "📍 *Anwani:* ${getShortAddress()}\n"
        "💰 *Bei:* $formattedPrice kwa mwezi\n"
        "🛏️ *Vyumba vya kulala:* $bedrooms\n"
        "🏷️ *Aina:* $type\n"
        "📋 *Hali:* $status\n\n"
        "📞 *Mawasiliano:* $phone\n"
        "${altPhone != null && altPhone!.isNotEmpty ? "📱 *Namba mbadala:* $altPhone\n" : ""}"
        "\n🔗 Tazama nyumba hii kwenye App yetu!";
  }

  // ========== HELPER METHOD 12: JINA KAMILI LA MWENYE NYUMBA ==========
  String getFullOwnerName() {
    if (lastName.isNotEmpty) {
      return "$firstName $lastName";
    }
    return firstName;
  }

  // ========== HELPER METHOD 13: MAELEZO YA NYUMBA KWA KIFUPI ==========
  String getShortDescription() {
    if (description.length > 100) {
      return "${description.substring(0, 100)}...";
    }
    return description;
  }

  // ========== HELPER METHOD 14: ANGALIA KAMA PICHA ZIPO ==========
  bool hasImages() {
    return images.isNotEmpty;
  }

  // ========== HELPER METHOD 15: PICHA YA KWANZA ==========
  String? getFirstImage() {
    return images.isNotEmpty ? images.first : null;
  }

  // ========== COPY METHOD ==========
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
    );
  }

  @override
  String toString() {
    return 'RentalSpot(name: $name, price: $formattedPrice, location: ${getShortAddress()})';
  }
}
