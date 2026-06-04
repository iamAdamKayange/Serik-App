class MaintenanceData {
  final String id;
  final String tenantName;
  final String houseName;
  final String issue;
  final String priority;
  final String status;
  final DateTime date;
  final String? assignedTo;

  MaintenanceData({
    required this.id,
    required this.tenantName,
    required this.houseName,
    required this.issue,
    required this.priority,
    required this.status,
    required this.date,
    this.assignedTo,
  });
}
