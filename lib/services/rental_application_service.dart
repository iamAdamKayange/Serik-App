import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/rental_application_model.dart';

class RentalApplicationService {
  static const String _storageKey = 'serik_tenant_rental_applications';
  static final ValueNotifier<List<RentalApplication>> applicationsNotifier =
      ValueNotifier<List<RentalApplication>>([]);

  static Future<void> init() async {
    await loadApplications();
  }

  static Future<List<RentalApplication>> loadApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_storageKey);
      if (dataStr != null && dataStr.isNotEmpty) {
        final list = RentalApplication.decode(dataStr);
        applicationsNotifier.value = list;
        return list;
      } else {
        // Seed initial sample applications for seamless tenant onboarding experience
        final sampleList = _getSampleApplications();
        await saveApplications(sampleList);
        return sampleList;
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
      return [];
    }
  }

  static Future<void> saveApplications(List<RentalApplication> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = RentalApplication.encode(list);
      await prefs.setString(_storageKey, dataStr);
      applicationsNotifier.value = List.from(list);
    } catch (e) {
      debugPrint('Error saving applications: $e');
    }
  }

  static Future<RentalApplication> submitApplication({
    required String houseId,
    required String houseTitle,
    required String houseImage,
    required String houseType,
    required double monthlyRent,
    required double depositAmount,
    required String location,
    required String ownerName,
    required String ownerPhone,
    required String applicantName,
    required String applicantPhone,
    required String applicantEmail,
    required DateTime moveInDate,
    required int leaseMonths,
    required int occupantsCount,
    required String notes,
    double? latitude,
    double? longitude,
  }) async {
    final newApp = RentalApplication(
      id: 'APP-${DateTime.now().millisecondsSinceEpoch}',
      houseId: houseId,
      houseTitle: houseTitle,
      houseImage: houseImage,
      houseType: houseType,
      monthlyRent: monthlyRent,
      depositAmount: depositAmount,
      location: location,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      applicantName: applicantName,
      applicantPhone: applicantPhone,
      applicantEmail: applicantEmail,
      appliedDate: DateTime.now(),
      moveInDate: moveInDate,
      leaseMonths: leaseMonths,
      occupantsCount: occupantsCount,
      notes: notes,
      status: ApplicationStatus.pending,
      latitude: latitude,
      longitude: longitude,
    );

    final currentList = await loadApplications();
    final updatedList = [newApp, ...currentList];
    await saveApplications(updatedList);
    return newApp;
  }

  static Future<bool> updateStatus(
    String applicationId,
    ApplicationStatus newStatus,
  ) async {
    final currentList = await loadApplications();
    final index = currentList.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      currentList[index].status = newStatus;
      await saveApplications(currentList);
      return true;
    }
    return false;
  }

  static Future<bool> deleteApplication(String applicationId) async {
    final currentList = await loadApplications();
    final updatedList =
        currentList.where((a) => a.id != applicationId).toList();
    await saveApplications(updatedList);
    return true;
  }

  static List<RentalApplication> _getSampleApplications() {
    return [
      RentalApplication(
        id: 'APP-10291',
        houseId: 'demo-1',
        houseTitle: 'Apartment ya Kisasa - Makumbusho',
        houseImage:
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
        houseType: 'Apartment',
        monthlyRent: 350000,
        depositAmount: 350000,
        location: 'Makumbusho, Kijitonyama, Kinondoni',
        ownerName: 'Mzee Juma Rashidi',
        ownerPhone: '0712345678',
        applicantName: 'Mwanafunzi / Mpangaji',
        applicantPhone: '0788123456',
        applicantEmail: 'mpangaji@serik.app',
        appliedDate: DateTime.now().subtract(const Duration(days: 2)),
        moveInDate: DateTime.now().add(const Duration(days: 5)),
        leaseMonths: 6,
        occupantsCount: 1,
        notes: 'Nahitaji kuhamia mwanzoni mwa muhula mpya wa chuo.',
        status: ApplicationStatus.approved,
        latitude: -6.7725,
        longitude: 39.2392,
      ),
      RentalApplication(
        id: 'APP-10292',
        houseId: 'demo-2',
        houseTitle: 'Chumba Master & Sebule - Chuo Kikuu (UDSM)',
        houseImage:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
        houseType: 'Chumba & Sebule',
        monthlyRent: 200000,
        depositAmount: 200000,
        location: 'Mlalakuwa, Karibu na Gate Kuu UDSM',
        ownerName: 'Bi. Rehema Said',
        ownerPhone: '0754987654',
        applicantName: 'Mwanafunzi / Mpangaji',
        applicantPhone: '0788123456',
        applicantEmail: 'mpangaji@serik.app',
        appliedDate: DateTime.now().subtract(const Duration(hours: 8)),
        moveInDate: DateTime.now().add(const Duration(days: 10)),
        leaseMonths: 12,
        occupantsCount: 2,
        notes: 'Chumba kipo karibu na chuo, niko tayari kulipa deposit.',
        status: ApplicationStatus.pending,
        latitude: -6.7816,
        longitude: 39.2056,
      ),
      RentalApplication(
        id: 'APP-10290',
        houseId: 'demo-3',
        houseTitle: 'Studio Apartment - Sinza Mori',
        houseImage:
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
        houseType: 'Studio',
        monthlyRent: 280000,
        depositAmount: 280000,
        location: 'Sinza Mori, Dar es Salaam',
        ownerName: 'Dr. Mwita John',
        ownerPhone: '0655112233',
        applicantName: 'Mwanafunzi / Mpangaji',
        applicantPhone: '0788123456',
        applicantEmail: 'mpangaji@serik.app',
        appliedDate: DateTime.now().subtract(const Duration(days: 45)),
        moveInDate: DateTime.now().subtract(const Duration(days: 35)),
        leaseMonths: 6,
        occupantsCount: 1,
        notes: 'Mkataba unaendelea vizuri.',
        status: ApplicationStatus.activeLease,
        latitude: -6.7834,
        longitude: 39.2215,
      ),
    ];
  }
}
