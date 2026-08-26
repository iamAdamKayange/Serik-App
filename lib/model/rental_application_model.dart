import 'dart:convert';

enum ApplicationStatus {
  pending, // Inapitiwa na mwenye nyumba
  approved, // Imekubaliwa
  rejected, // Imekataliwa
  depositPaid, // Deposit imelipwa
  activeLease, // Mkataba umeanza rasmi
  completed, // Mkataba umekwisha
}

class RentalApplication {
  final String id;
  final String houseId;
  final String houseTitle;
  final String houseImage;
  final String houseType;
  final double monthlyRent;
  final double depositAmount;
  final String location;
  final String ownerName;
  final String ownerPhone;
  final String applicantName;
  final String applicantPhone;
  final String applicantEmail;
  final DateTime appliedDate;
  final DateTime moveInDate;
  final int leaseMonths;
  final int occupantsCount;
  final String notes;
  ApplicationStatus status;
  final double? latitude;
  final double? longitude;

  RentalApplication({
    required this.id,
    required this.houseId,
    required this.houseTitle,
    required this.houseImage,
    required this.houseType,
    required this.monthlyRent,
    required this.depositAmount,
    required this.location,
    required this.ownerName,
    required this.ownerPhone,
    required this.applicantName,
    required this.applicantPhone,
    required this.applicantEmail,
    required this.appliedDate,
    required this.moveInDate,
    required this.leaseMonths,
    required this.occupantsCount,
    required this.notes,
    this.status = ApplicationStatus.pending,
    this.latitude,
    this.longitude,
  });

  String get statusTitleSw {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Inapitiwa';
      case ApplicationStatus.approved:
        return 'Imekubaliwa';
      case ApplicationStatus.rejected:
        return 'Imekataliwa';
      case ApplicationStatus.depositPaid:
        return 'Deposit Imelipwa';
      case ApplicationStatus.activeLease:
        return 'Mkataba Umeanza';
      case ApplicationStatus.completed:
        return 'Mkataba Umekwisha';
    }
  }

  String get statusTitleEn {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Under Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.depositPaid:
        return 'Deposit Paid';
      case ApplicationStatus.activeLease:
        return 'Active Lease';
      case ApplicationStatus.completed:
        return 'Completed';
    }
  }

  int get timelineStep {
    switch (status) {
      case ApplicationStatus.pending:
        return 1;
      case ApplicationStatus.approved:
        return 2;
      case ApplicationStatus.depositPaid:
        return 3;
      case ApplicationStatus.activeLease:
        return 4;
      case ApplicationStatus.completed:
        return 4;
      case ApplicationStatus.rejected:
        return 1;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseId': houseId,
      'houseTitle': houseTitle,
      'houseImage': houseImage,
      'houseType': houseType,
      'monthlyRent': monthlyRent,
      'depositAmount': depositAmount,
      'location': location,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'applicantName': applicantName,
      'applicantPhone': applicantPhone,
      'applicantEmail': applicantEmail,
      'appliedDate': appliedDate.toIso8601String(),
      'moveInDate': moveInDate.toIso8601String(),
      'leaseMonths': leaseMonths,
      'occupantsCount': occupantsCount,
      'notes': notes,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory RentalApplication.fromJson(Map<String, dynamic> json) {
    return RentalApplication(
      id: json['id']?.toString() ?? '',
      houseId: json['houseId']?.toString() ?? '',
      houseTitle: json['houseTitle']?.toString() ?? 'Nyumba ya Kupanga',
      houseImage: json['houseImage']?.toString() ?? '',
      houseType: json['houseType']?.toString() ?? 'Apartment',
      monthlyRent: (json['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      location: json['location']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? 'Mwenye Nyumba',
      ownerPhone: json['ownerPhone']?.toString() ?? '',
      applicantName: json['applicantName']?.toString() ?? '',
      applicantPhone: json['applicantPhone']?.toString() ?? '',
      applicantEmail: json['applicantEmail']?.toString() ?? '',
      appliedDate: DateTime.tryParse(json['appliedDate']?.toString() ?? '') ??
          DateTime.now(),
      moveInDate: DateTime.tryParse(json['moveInDate']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      leaseMonths: (json['leaseMonths'] as num?)?.toInt() ?? 6,
      occupantsCount: (json['occupantsCount'] as num?)?.toInt() ?? 1,
      notes: json['notes']?.toString() ?? '',
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  static String encode(List<RentalApplication> applications) => json.encode(
        applications.map<Map<String, dynamic>>((a) => a.toJson()).toList(),
      );

  static List<RentalApplication> decode(String applicationsStr) =>
      (json.decode(applicationsStr) as List<dynamic>)
          .map<RentalApplication>(
            (item) => RentalApplication.fromJson(item as Map<String, dynamic>),
          )
          .toList();
}
