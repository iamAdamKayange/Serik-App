class LocationItem {
  // ========== MKAO (REGION) ==========
  final String region; // Mkoa
  final String postcodeRegion; // Postcode ya Mkoa

  // ========== WILAYA (DISTRICT) ==========
  final String district; // Wilaya
  final String postcodeDistrict; // Postcode ya Wilaya

  // ========== TARAFA (DIVISION) ==========
  final String division; // Tarafa 🆕
  final String postcodeDivision; // Postcode ya Tarafa 🆕

  // ========== KATA (WARD) ==========
  final String ward; // Kata
  final String postcodeWard; // Postcode ya Kata

  // ========== KIJIJI (VILLAGE) ==========
  final String village; // Kijiji 🆕
  final String postcodeVillage; // Postcode ya Kijiji 🆕

  // ========== MTAA (STREET) ==========
  final String street; // Mtaa / Barabara

  // ========== OTHER ==========
  final String places; // Majina ya maeneo / vivutio

  LocationItem({
    required this.region,
    required this.postcodeRegion,
    required this.district,
    required this.postcodeDistrict,
    this.division = '', // 🆕 Default empty
    this.postcodeDivision = '', // 🆕 Default empty
    required this.ward,
    required this.postcodeWard,
    this.village = '', // 🆕 Default empty
    this.postcodeVillage = '', // 🆕 Default empty
    required this.street,
    this.places = '', // Default empty
  });

  // Factory constructor kutoka List (kwa CSV data)
  factory LocationItem.fromList(List<dynamic> list) {
    return LocationItem(
      // Column 0-1: Region
      region: list.isNotEmpty ? list[0].toString() : '',
      postcodeRegion: list.length > 1 ? list[1].toString() : '',

      // Column 2-3: District
      district: list.length > 2 ? list[2].toString() : '',
      postcodeDistrict: list.length > 3 ? list[3].toString() : '',

      // Column 4-5: Division (Tarafa) 🆕
      division: list.length > 4 ? list[4].toString() : '',
      postcodeDivision: list.length > 5 ? list[5].toString() : '',

      // Column 6-7: Ward (Kata)
      ward: list.length > 6 ? list[6].toString() : '',
      postcodeWard: list.length > 7 ? list[7].toString() : '',

      // Column 8-9: Village (Kijiji) 🆕
      village: list.length > 8 ? list[8].toString() : '',
      postcodeVillage: list.length > 9 ? list[9].toString() : '',

      // Column 10: Street
      street: list.length > 10 ? list[10].toString() : '',

      // Column 11: Places
      places: list.length > 11 ? list[11].toString() : '',
    );
  }

  // 🆕 Factory constructor kutoka Map (kwa JSON/API)
  factory LocationItem.fromMap(Map<String, dynamic> map) {
    return LocationItem(
      region: map['region'] ?? '',
      postcodeRegion: map['postcodeRegion'] ?? '',
      district: map['district'] ?? '',
      postcodeDistrict: map['postcodeDistrict'] ?? '',
      division: map['division'] ?? '',
      postcodeDivision: map['postcodeDivision'] ?? '',
      ward: map['ward'] ?? '',
      postcodeWard: map['postcodeWard'] ?? '',
      village: map['village'] ?? '',
      postcodeVillage: map['postcodeVillage'] ?? '',
      street: map['street'] ?? '',
      places: map['places'] ?? '',
    );
  }

  // 🆕 Convert to Map (kwa JSON/API)
  Map<String, dynamic> toMap() {
    return {
      'region': region,
      'postcodeRegion': postcodeRegion,
      'district': district,
      'postcodeDistrict': postcodeDistrict,
      'division': division,
      'postcodeDivision': postcodeDivision,
      'ward': ward,
      'postcodeWard': postcodeWard,
      'village': village,
      'postcodeVillage': postcodeVillage,
      'street': street,
      'places': places,
    };
  }

  // 🆕 Helper method: Get full address in Swahili
  String getFullSwahiliAddress() {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add("Mtaa: $street");
    if (village.isNotEmpty) parts.add("Kijiji: $village");
    if (ward.isNotEmpty) parts.add("Kata: $ward");
    if (division.isNotEmpty) parts.add("Tarafa: $division");
    if (district.isNotEmpty) parts.add("Wilaya: $district");
    if (region.isNotEmpty) parts.add("Mkoa: $region");
    return parts.isNotEmpty ? parts.join(", ") : "Anwani haijakamilika";
  }

  // 🆕 Helper method: Get short address for display
  String getShortAddress() {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (ward.isNotEmpty) parts.add(ward);
    if (district.isNotEmpty) parts.add(district);
    if (region.isNotEmpty) parts.add(region);
    return parts.join(", ");
  }

  // 🆕 Helper method: Get address for map marker
  String getMapAddress() {
    List<String> parts = [];
    if (ward.isNotEmpty) parts.add(ward);
    if (district.isNotEmpty) parts.add(district);
    if (region.isNotEmpty) parts.add(region);
    return parts.join(", ");
  }

  // 🆕 Helper method: Check if location has complete hierarchy
  bool hasCompleteHierarchy() {
    return region.isNotEmpty &&
        district.isNotEmpty &&
        ward.isNotEmpty &&
        street.isNotEmpty;
  }

  // 🆕 Helper method: Get postcode summary
  String getPostcodeSummary() {
    List<String> postcodes = [];
    if (postcodeRegion.isNotEmpty) postcodes.add("Region: $postcodeRegion");
    if (postcodeDistrict.isNotEmpty) {
      postcodes.add("District: $postcodeDistrict");
    }
    if (postcodeDivision.isNotEmpty) {
      postcodes.add("Division: $postcodeDivision");
    }
    if (postcodeWard.isNotEmpty) postcodes.add("Ward: $postcodeWard");
    if (postcodeVillage.isNotEmpty) postcodes.add("Village: $postcodeVillage");
    return postcodes.join(" | ");
  }

  // 🆕 Helper method: Check if division exists
  bool hasDivision() {
    return division.isNotEmpty && division != 'Hakuna Tarafa';
  }

  // 🆕 Helper method: Check if village exists
  bool hasVillage() {
    return village.isNotEmpty && village != 'Hakuna Kijiji';
  }

  // 🆕 Helper method: Get places list as array
  List<String> getPlacesList() {
    if (places.isEmpty) return [];
    return places.split(',').map((p) => p.trim()).toList();
  }

  // 🆕 Copy with method
  LocationItem copyWith({
    String? region,
    String? postcodeRegion,
    String? district,
    String? postcodeDistrict,
    String? division,
    String? postcodeDivision,
    String? ward,
    String? postcodeWard,
    String? village,
    String? postcodeVillage,
    String? street,
    String? places,
  }) {
    return LocationItem(
      region: region ?? this.region,
      postcodeRegion: postcodeRegion ?? this.postcodeRegion,
      district: district ?? this.district,
      postcodeDistrict: postcodeDistrict ?? this.postcodeDistrict,
      division: division ?? this.division,
      postcodeDivision: postcodeDivision ?? this.postcodeDivision,
      ward: ward ?? this.ward,
      postcodeWard: postcodeWard ?? this.postcodeWard,
      village: village ?? this.village,
      postcodeVillage: postcodeVillage ?? this.postcodeVillage,
      street: street ?? this.street,
      places: places ?? this.places,
    );
  }

  @override
  String toString() {
    return 'LocationItem(region: $region, district: $district, division: $division, ward: $ward, village: $village, street: $street)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationItem &&
        other.region == region &&
        other.district == district &&
        other.division == division &&
        other.ward == ward &&
        other.village == village &&
        other.street == street;
  }

  @override
  int get hashCode {
    return Object.hash(region, district, division, ward, village, street);
  }
}
