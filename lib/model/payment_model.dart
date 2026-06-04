class PaymentData {
  final String id;
  final String tenantId;
  final String tenantName;
  final double amount;
  final DateTime date;
  final String status;
  final String month;

  PaymentData({
    required this.id,
    required this.tenantName,
    required this.tenantId,
    required this.amount,
    required this.date,
    required this.status,
    required this.month,
  });
}
