class TenantData {
  final String id;
  final String name;
  final String phone;
  final String houseId;
  final String houseName;
  final double rentAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  TenantData({
    required this.id,
    required this.name,
    required this.phone,
    required this.houseId,
    required this.houseName,
    required this.rentAmount,
    required this.startDate,
    this.endDate,
    required this.status,
  });
}
