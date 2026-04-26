// lib/pages/rental_home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/pages/house_registration_page.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RentalHomePage extends StatefulWidget {
  const RentalHomePage({super.key});

  @override
  State<RentalHomePage> createState() => _RentalHomePageState();
}

class _RentalHomePageState extends State<RentalHomePage> {
  List<HouseData> houses = [];
  List<TenantData> tenants = [];
  List<PaymentData> payments = [];
  List<MaintenanceData> maintenanceRequests = [];
  List<ChartData> chartData = [];
  int _currentIndex = 0;
  bool _isLoadingHouses = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ============ LOAD DATA FROM API ============
  Future<void> _loadAllData() async {
    await _loadHousesFromAPI();
    _loadSampleData();
  }

  Future<void> _loadHousesFromAPI() async {
    setState(() {
      _isLoadingHouses = true;
    });

    try {
      debugPrint('📥 Loading houses from API...');
      final apiHouses = await ApiService.getUserHouses();
      debugPrint('✅ Loaded ${apiHouses.length} houses from API');

      setState(() {
        houses = apiHouses;
        _isLoadingHouses = false;
      });

      for (var house in houses) {
        debugPrint('🏠 House: ${house.name}, Status: ${house.status}');
      }
    } catch (e) {
      debugPrint('❌ Error loading houses: $e');
      setState(() {
        _isLoadingHouses = false;
      });
      _showError("Hitilafu katika kupakua nyumba: $e");
    }
  }

  void _loadSampleData() {
    tenants = [
      TenantData(
        id: '1',
        name: 'Adam Kayange',
        phone: '0712345678',
        houseId: '1',
        houseName: 'Nyumba ya Kati',
        rentAmount: 250000,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 305)),
        status: 'Active',
      ),
      TenantData(
        id: '2',
        name: 'Yusuph Mwashi',
        phone: '0755123456',
        houseId: '2',
        houseName: 'Studio Mpya',
        rentAmount: 350000,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        status: 'Active',
      ),
    ];

    payments = [
      PaymentData(
        id: '1',
        tenantName: 'Adam Kayange',
        amount: 250000,
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Paid',
        month: 'Novemba 2024',
        tenantId: '1',
      ),
      PaymentData(
        id: '2',
        tenantName: 'Yusuph Mwashi',
        amount: 350000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Pending',
        month: 'Novemba 2024',
        tenantId: '2',
      ),
    ];

    maintenanceRequests = [
      MaintenanceData(
        id: '1',
        tenantName: 'Adam Kayange',
        houseName: 'Nyumba ya Kati',
        issue: 'Mfereji unatoboka',
        priority: 'High',
        status: 'Inasubiri',
        date: DateTime.now().subtract(const Duration(days: 2)),
        assignedTo: 'Fundi Juma',
      ),
      MaintenanceData(
        id: '2',
        tenantName: 'Yusuph Mwashi',
        houseName: 'Studio Mpya',
        issue: 'Taa haiwashi',
        priority: 'Medium',
        status: 'Inarudiwa',
        date: DateTime.now().subtract(const Duration(days: 1)),
        assignedTo: 'Fundi Ali',
      ),
    ];

    _generateChartData();
  }

  void _generateChartData() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    final currentMonth = now.month;

    chartData = [];

    for (int i = 5; i >= 0; i--) {
      final monthIndex = (currentMonth - i - 1) % 12;
      final monthName = months[monthIndex];
      final baseAmount = 250000.0;
      final randomFactor = 0.8 + (0.4 * (i % 3));
      final amount = (baseAmount * randomFactor).roundToDouble();

      chartData.add(ChartData(monthName, amount));
    }
  }

  // ============ HOUSE MANAGEMENT FUNCTIONS ============
  void _addHouse(HouseData newHouse) async {
    setState(() {
      houses.add(newHouse);
    });
    _showSuccessMessage("Nyumba imesajiliwa kikamilifu!");
    await _loadHousesFromAPI();
  }

  void _editHouse(HouseData house) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: house.name);
        final priceController = TextEditingController(
          text: house.rentPrice.toString(),
        );
        String selectedStatus = house.status;

        return AlertDialog(
          title: const Text('Hariri Nyumba'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Jina la Nyumba',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Kodi (TZS)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ['Inapatikana', 'Imekodishwa', 'Inamatengenezo']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedStatus = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Hali ya Nyumba',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedHouse = house.copyWith(
                  name: nameController.text,
                  rentPrice:
                      double.tryParse(priceController.text) ?? house.rentPrice,
                  status: selectedStatus,
                );

                final success = await ApiService.updateHouse(house.id, {
                  'name': updatedHouse.name,
                  'status': updatedHouse.status,
                  'rentPrice': updatedHouse.rentPrice,
                });

                if (success) {
                  setState(() {
                    final index = houses.indexWhere((h) => h.id == house.id);
                    if (index != -1) {
                      houses[index] = updatedHouse;
                    }
                  });
                  Navigator.pop(context);
                  _showSuccessMessage("Taarifa za nyumba zimebadilishwa!");
                } else {
                  _showError("Hitilafu katika kuhifadhi mabadiliko");
                }
              },
              child: const Text('Hifadhi'),
            ),
          ],
        );
      },
    );
  }

  void _deleteHouse(String houseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thibitisha'),
        content: const Text('Unataka kufuta nyumba hii?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService.deleteHouse(houseId);

              if (success) {
                setState(() {
                  houses.removeWhere((house) => house.id == houseId);
                  tenants.removeWhere((t) => t.houseId == houseId);
                  final tenantIds = tenants
                      .where((t) => t.houseId == houseId)
                      .map((t) => t.id)
                      .toList();
                  payments.removeWhere((p) => tenantIds.contains(p.tenantId));
                });
                Navigator.pop(context);
                _showSuccessMessage("Nyumba imefutwa kikamilifu!");
              } else {
                _showError("Hitilafu katika kufuta nyumba");
              }
            },
            child: const Text('Ndiyo'),
          ),
        ],
      ),
    );
  }

  void _updateHouseStatus(String houseId, String newStatus) {
    final index = houses.indexWhere((h) => h.id == houseId);
    if (index == -1) return;

    final updatedHouse = houses[index].copyWith(status: newStatus);

    ApiService.updateHouse(houseId, {'status': newStatus});

    setState(() {
      houses[index] = updatedHouse;
    });

    _showSuccessMessage("Hali ya nyumba imesasishwa!");
  }

  // ============ TENANT MANAGEMENT FUNCTIONS ============
  void _addTenant(TenantData newTenant) {
    setState(() {
      tenants.add(newTenant);
      _updateHouseStatus(newTenant.houseId, 'Imekodishwa');
    });
    _showSuccessMessage("Mkodishi amesajiliwa kikamilifu!");
  }

  void _removeTenant(String tenantId) {
    final tenant = tenants.firstWhere((t) => t.id == tenantId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Mkodishi'),
        content: Text('Unataka kufuta ${tenant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                tenants.removeWhere((t) => t.id == tenantId);
                _updateHouseStatus(tenant.houseId, 'Inapatikana');
                payments.removeWhere((p) => p.tenantId == tenantId);
              });
              Navigator.pop(context);
              _showSuccessMessage("Mkodishi amefutwa kikamilifu!");
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  void _renewTenantContract(String tenantId, DateTime newEndDate) {
    setState(() {
      final tenant = tenants.firstWhere((t) => t.id == tenantId);
      tenant.endDate = newEndDate;
    });
    _showSuccessMessage("Mkataba umeongezewa muda!");
  }

  // ============ PAYMENT MANAGEMENT FUNCTIONS ============
  void _recordPayment(PaymentData payment) {
    setState(() {
      payments.add(payment);
    });
    _showSuccessMessage("Malipo yameandikwa kikamilifu!");
  }

  void _markPaymentAsPaid(String paymentId) {
    setState(() {
      final payment = payments.firstWhere((p) => p.id == paymentId);
      payment.status = 'Paid';
    });
    _showSuccessMessage("Malipo yamehakikiwa!");
    _generateChartData();
  }

  void _sendPaymentReminder(String tenantId) {
    final tenant = tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => TenantData(
        id: tenantId,
        name: 'Mpangaji',
        phone: '',
        houseId: '',
        houseName: '',
        rentAmount: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        status: '',
      ),
    );
    _showSuccessMessage("Ukumbusho wa malipo umetumwa kwa ${tenant.name}!");
  }

  // ============ MAINTENANCE MANAGEMENT FUNCTIONS ============
  void _submitMaintenanceRequest(MaintenanceData request) {
    setState(() {
      maintenanceRequests.add(request);
    });
    _showSuccessMessage("Ombi la matengenezo limewasilishwa!");
  }

  void _updateMaintenanceStatus(String requestId, String newStatus) {
    setState(() {
      final request = maintenanceRequests.firstWhere((r) => r.id == requestId);
      request.status = newStatus;
    });
    _showSuccessMessage("Hali ya matengenezo imesasishwa!");
  }

  void _assignMaintenanceWorker(String requestId, String workerName) {
    setState(() {
      final request = maintenanceRequests.firstWhere((r) => r.id == requestId);
      request.assignedTo = workerName;
      request.status = 'Inarudiwa';
    });
    _showSuccessMessage("Fundi $workerName ameteuliwa!");
  }

  // ============ FINANCIAL REPORTS FUNCTIONS ============
  double _calculateMonthlyIncome() {
    final now = DateTime.now();
    final currentMonth = '${_getMonthName(now.month)} ${now.year}';

    return payments
        .where((p) => p.status == 'Paid' && p.month.contains(currentMonth))
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _calculateAnnualIncome() {
    final now = DateTime.now();
    final currentYear = now.year.toString();

    return payments
        .where((p) => p.status == 'Paid' && p.month.contains(currentYear))
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  List<PaymentData> _getPendingPayments() {
    return payments.where((p) => p.status == 'Pending').toList();
  }

  // ============ NOTIFICATION FUNCTIONS ============
  void _sendBulkNotification(String message) {
    if (tenants.isEmpty) {
      _showError("Hakuna wapangaji wa kutuma tangazo");
      return;
    }
    for (var t in tenants) {
      print('📨 Sending notification to ${t.name}: $message');
    }
    _showSuccessMessage("Tangazo limetumwa kwa wakodishi ${tenants.length}!");
  }

  void _sendRentIncreaseNotice(String tenantId, double newRent) {
    final tenant = tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => TenantData(
        id: tenantId,
        name: 'Mpangaji',
        phone: '',
        houseId: '',
        houseName: '',
        rentAmount: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        status: '',
      ),
    );
    _showSuccessMessage(
      "Ilani ya ongezeko la kodi imetumwa kwa ${tenant.name}!",
    );
  }

  // ============ DOCUMENT MANAGEMENT FUNCTIONS ============
  void _generateRentReceipt(String paymentId) {
    final payment = payments.firstWhere(
      (p) => p.id == paymentId,
      orElse: () => PaymentData(
        id: paymentId,
        tenantName: 'Unknown',
        amount: 0,
        date: DateTime.now(),
        status: 'Pending',
        month: _getCurrentMonth(),
        tenantId: '',
      ),
    );
    _showSuccessMessage(
      "Risiti ya malipo imetengenezwa kwa ${payment.tenantName}!",
    );
  }

  void _generateContract(String tenantId) {
    final tenant = tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => TenantData(
        id: tenantId,
        name: 'Unknown',
        phone: '',
        houseId: '',
        houseName: '',
        rentAmount: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        status: '',
      ),
    );
    _showSuccessMessage("Mkataba umetengenezwa kwa ${tenant.name}!");
  }

  void _exportFinancialReport() {
    final monthlyIncome = _calculateMonthlyIncome();
    final annualIncome = _calculateAnnualIncome();
    final pendingPayments = _getPendingPayments().length;

    debugPrint('📊 Financial Report Exported:');
    debugPrint('   Monthly Income: TZS $monthlyIncome');
    debugPrint('   Annual Income: TZS $annualIncome');
    debugPrint('   Pending Payments: $pendingPayments');

    _showSuccessMessage("Taarifa ya kifedha imepakuliwa kikamilifu!");
  }

  // ============ UTILITY FUNCTIONS ============
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
      'Januari',
      'Februari',
      'Machi',
      'Aprili',
      'Mei',
      'Juni',
      'Julai',
      'Agosti',
      'Septemba',
      'Oktoba',
      'Novemba',
      'Desemba',
    ];
    return months[month - 1];
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${_getMonthName(now.month)} ${now.year}';
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // ============ BUILD METHODS ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0
          ? _buildFloatingActionButton()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "SERIK APP - MPANGISHAJI",
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded),
          onPressed: _showNotifications,
          tooltip: "Arifa",
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshData,
          tooltip: "Pakia upya",
        ),
      ],
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardScreen();
      case 1:
        return _buildTenantsScreen();
      case 2:
        return _buildPaymentsScreen();
      case 3:
        return _buildMaintenanceScreen();
      case 4:
        return _buildReportsScreen();
      default:
        return _buildDashboardScreen();
    }
  }

  Widget _buildDashboardScreen() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildRecentActivity(),
            const SizedBox(height: 20),
            _buildHouseListPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantsScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                "WAPANGAJI",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddTenantForm,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text("Ongeza Mpangaji"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tenants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hakuna wapangaji",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Bonyeza 'Ongeza Mpangaji' kuwaongeza",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    return _buildTenantCard(tenants[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentsScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                "MALIPO",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showRecordPaymentForm,
                icon: const Icon(Icons.payment_rounded),
                label: const Text("Andika Malipo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hakuna malipo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Bonyeza 'Andika Malipo' kuyaongeza",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(payments[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                "MATENGENEZO",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showMaintenanceForm,
                icon: const Icon(Icons.handyman_rounded, size: 18),
                label: const Text("Omba Matengenezo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: maintenanceRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handyman_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hakuna matengenezo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Bonyeza 'Omba Matengenezo' kuyaongeza",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: maintenanceRequests.length,
                  itemBuilder: (context, index) {
                    return _buildMaintenanceCard(maintenanceRequests[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportsScreen() {
    final pending = _getPendingPayments();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFinancialSummary(),
          const SizedBox(height: 20),
          _buildIncomeChart(),
          const SizedBox(height: 20),
          _buildReportActions(),
          const SizedBox(height: 20),
          if (pending.isNotEmpty) ...[
            const Text(
              "MALIPO YANALIPWA",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...pending.map(
              (p) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.pending_rounded,
                    color: Colors.orange,
                  ),
                  title: Text(p.tenantName),
                  subtitle: Text(p.month),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "TZS ${p.amount.toInt()}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        "Inasubiri",
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                  onTap: () {
                    _markPaymentAsPaid(p.id);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // ============ UI COMPONENTS ============
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Karibu Mpangishaji!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Idadi ya nyumba: ${houses.length}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  "Wapangaji: ${tenants.length}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  "Mapato ya mwezi: TZS ${_calculateMonthlyIncome().toInt()}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const Icon(Icons.home_work_rounded, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Nyumba",
            houses.length.toString(),
            Icons.home_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Wapangaji",
            tenants.length.toString(),
            Icons.people_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Mapato",
            "TZS ${_calculateMonthlyIncome().toInt()}",
            Icons.monetization_on_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vitendo Haraka",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              "Nyumba Mpya",
              Icons.add_home_rounded,
              Colors.blue,
              _showAddHouseForm,
            ),
            _buildActionCard(
              "Wapangaji",
              Icons.person_add_rounded,
              Colors.green,
              _showAddTenantForm,
            ),
            _buildActionCard(
              "Malipo",
              Icons.payment_rounded,
              Colors.orange,
              _showRecordPaymentForm,
            ),
            _buildActionCard(
              "Matengenezo",
              Icons.handyman_rounded,
              Colors.purple,
              _showMaintenanceForm,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final recentPayments = payments.length > 3
        ? payments.sublist(0, payments.length > 3 ? 3 : payments.length)
        : payments;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Shughuli Za Karibuni",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (recentPayments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Hakuna shughuli za hivi karibuni",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: recentPayments
                    .map(
                      (payment) => ListTile(
                        leading: Icon(
                          payment.status == 'Paid'
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          color: payment.status == 'Paid'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(payment.tenantName),
                        subtitle: Text(payment.month),
                        trailing: Text(
                          "TZS ${payment.amount.toInt()}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          if (payment.status == 'Pending') {
                            _markPaymentAsPaid(payment.id);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseListPreview() {
    if (_isLoadingHouses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (houses.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.home_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                "Hakuna nyumba zilizosajiliwa",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showAddHouseForm,
                icon: const Icon(Icons.add_home_rounded),
                label: const Text("Sajili Nyumba Kwanza"),
              ),
            ],
          ),
        ),
      );
    }

    final recentHouses = houses.length > 2
        ? houses.sublist(0, houses.length > 2 ? 2 : houses.length)
        : houses;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nyumba Zako",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...recentHouses.map(
              (house) => ListTile(
                leading: const Icon(Icons.home_rounded, color: Colors.blue),
                title: Text(house.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(house.location),
                    Text(
                      "TZS ${house.rentPrice.toInt()} • ${house.status}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editHouse(house);
                    if (value == 'delete') _deleteHouse(house.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Hariri')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Futa', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
            if (houses.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showSuccessMessage("Onyesha orodha kamili ya nyumba");
                    },
                    child: const Text('Onyesha Nyumba Zote'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(TenantData tenant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.person_rounded, color: Colors.blue),
        ),
        title: Text(
          tenant.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tenant.houseName),
            Text(
              "Kodi: TZS ${tenant.rentAmount.toInt()} • ${tenant.status}",
              style: const TextStyle(fontSize: 12),
            ),
            if (tenant.endDate != null)
              Text(
                "Mwisho: ${_formatDate(tenant.endDate!)}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'renew') {
              _showRenewContractDialog(tenant);
            } else if (value == 'increase') {
              _showRentIncreaseDialog(tenant);
            } else if (value == 'reminder') {
              _sendPaymentReminder(tenant.id);
            } else if (value == 'contract') {
              _generateContract(tenant.id);
            } else if (value == 'remove') {
              _removeTenant(tenant.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'renew', child: Text('Renew Contract')),
            const PopupMenuItem(
              value: 'increase',
              child: Text('Increase Rent'),
            ),
            const PopupMenuItem(
              value: 'reminder',
              child: Text('Send Reminder'),
            ),
            const PopupMenuItem(
              value: 'contract',
              child: Text('Generate Contract'),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove Tenant', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(tenant.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nyumba: ${tenant.houseName}"),
                  Text("Simu: ${tenant.phone}"),
                  Text("Kodi: TZS ${tenant.rentAmount.toInt()}"),
                  Text("Hali: ${tenant.status}"),
                  Text("Kuanzia: ${_formatDate(tenant.startDate)}"),
                  if (tenant.endDate != null)
                    Text("Mwisho: ${_formatDate(tenant.endDate!)}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sawa'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _sendPaymentReminder(tenant.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Tuma Ukumbusho'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentData payment) {
    final isPaid = payment.status == 'Paid';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPaid ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          payment.tenantName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isPaid ? Colors.green[800] : Colors.orange[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.month),
            Text("Tarehe: ${_formatDate(payment.date)}"),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "TZS ${payment.amount.toInt()}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPaid ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                payment.status,
                style: TextStyle(
                  color: isPaid ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Malipo - ${payment.tenantName}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mwezi: ${payment.month}"),
                  Text("Kiasi: TZS ${payment.amount.toInt()}"),
                  Text("Tarehe: ${_formatDate(payment.date)}"),
                  Text("Hali: ${payment.status}"),
                  if (!isPaid) const SizedBox(height: 16),
                  if (!isPaid)
                    const Text(
                      "Bonyeza 'Mark as Paid' kudai malipo haya",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sawa'),
                ),
                if (!isPaid)
                  ElevatedButton(
                    onPressed: () {
                      _markPaymentAsPaid(payment.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Mark as Paid'),
                  ),
                if (isPaid)
                  ElevatedButton(
                    onPressed: () {
                      _generateRentReceipt(payment.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Generate Receipt'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(MaintenanceData maintenance) {
    Color priorityColor = Colors.green;
    if (maintenance.priority == 'Medium') priorityColor = Colors.orange;
    if (maintenance.priority == 'High') priorityColor = Colors.red;

    Color statusColor = Colors.orange;
    if (maintenance.status == 'Inarudiwa') statusColor = Colors.blue;
    if (maintenance.status == 'Imetatuliwa') statusColor = Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: priorityColor),
          ),
          child: Icon(Icons.handyman_rounded, color: priorityColor, size: 20),
        ),
        title: Text(
          maintenance.issue,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${maintenance.houseName} • ${maintenance.tenantName}"),
            Text("Tarehe: ${_formatDate(maintenance.date)}"),
            if (maintenance.assignedTo != null)
              Text(
                "Fundi: ${maintenance.assignedTo}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priorityColor),
              ),
              child: Text(
                maintenance.priority,
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              maintenance.status,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Maelezo ya Matengenezo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tatizo: ${maintenance.issue}"),
                  Text("Nyumba: ${maintenance.houseName}"),
                  Text("Mpangaji: ${maintenance.tenantName}"),
                  Text("Kipaumbele: ${maintenance.priority}"),
                  Text("Hali: ${maintenance.status}"),
                  Text("Tarehe: ${_formatDate(maintenance.date)}"),
                  if (maintenance.assignedTo != null)
                    Text("Fundi: ${maintenance.assignedTo}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sawa'),
                ),
                if (maintenance.status != 'Imetatuliwa')
                  ElevatedButton(
                    onPressed: () {
                      _updateMaintenanceStatus(maintenance.id, 'Imetatuliwa');
                      Navigator.pop(context);
                    },
                    child: const Text('Mark as Resolved'),
                  ),
                if (maintenance.assignedTo == null)
                  ElevatedButton(
                    onPressed: () {
                      _assignMaintenanceWorker(maintenance.id, 'Fundi Juma');
                      Navigator.pop(context);
                    },
                    child: const Text('Assign Worker'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final monthlyIncome = _calculateMonthlyIncome();
    final annualIncome = _calculateAnnualIncome();
    final pendingCount = _getPendingPayments().length;
    final paidCount = payments.where((p) => p.status == 'Paid').length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "MUHTASARI WA KIFEDHA",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialStat(
                    "Mapato ya Mwezi",
                    "TZS ${monthlyIncome.toInt()}",
                    Colors.green,
                    Icons.monetization_on_rounded,
                  ),
                ),
                Expanded(
                  child: _buildFinancialStat(
                    "Mapato ya Mwaka",
                    "TZS ${annualIncome.toInt()}",
                    Colors.blue,
                    Icons.timeline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialStat(
                    "Malipo Yanalipwa",
                    pendingCount.toString(),
                    Colors.orange,
                    Icons.pending_rounded,
                  ),
                ),
                Expanded(
                  child: _buildFinancialStat(
                    "Malipo Yaliyolipwa",
                    paidCount.toString(),
                    Colors.green,
                    Icons.check_circle_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exportFinancialReport,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Pakua Taarifa'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "HISTORIA YA MAPATO (Miezi 6 Iliyopita)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(
                    symbol: 'TZS ',
                    decimalDigits: 0,
                  ),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.month,
                    yValueMapper: (ChartData data, _) => data.value,
                    name: 'Mapato',
                    color: Colors.blue,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final pending = _getPendingPayments();
              if (pending.isEmpty) {
                _showSuccessMessage('Hakuna malipo yaliyosubiri.');
                return;
              }

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Malipo Yanalipwa'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: pending
                          .map(
                            (p) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.pending_rounded,
                                  color: Colors.orange,
                                ),
                                title: Text(p.tenantName),
                                subtitle: Text(p.month),
                                trailing: Text("TZS ${p.amount}"),
                                onTap: () {
                                  _markPaymentAsPaid(p.id);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sawa'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.receipt_rounded),
            label: const Text("Onyesha Malipo"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportFinancialReport,
            icon: const Icon(Icons.download_rounded),
            label: const Text("Pakua Taarifa"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1565C0),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashibodi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Wapangaji',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment_rounded),
          label: 'Malipo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.handyman_rounded),
          label: 'Matengenezo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_rounded),
          label: 'Taarifa',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickActionsMenu,
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add_rounded),
    );
  }

  // ============ DIALOG FORMS ============
  void _showAddHouseForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseRegistrationForm(onHouseAdded: _addHouse),
      ),
    ).then((_) {
      _loadHousesFromAPI();
    });
  }

  void _showAddTenantForm() {
    if (houses.isEmpty) {
      _showError("Hakuna nyumba zilizopo. Ongeza nyumba kwanza.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final phoneCtrl = TextEditingController();
        String selectedHouseId = houses.first.id;
        final rentCtrl = TextEditingController();

        return AlertDialog(
          title: const Text('Ongeza Mpangaji'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jina la Mpangaji',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Namba ya Simu',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedHouseId,
                  items: houses
                      .map(
                        (h) => DropdownMenuItem(
                          value: h.id,
                          child: Text("${h.name} - TZS ${h.rentPrice.toInt()}"),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedHouseId = v ?? selectedHouseId,
                  decoration: const InputDecoration(
                    labelText: 'Chagua Nyumba',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kodi (TZS)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) {
                  _showError("Tafadhali weka jina la mpangaji");
                  return;
                }

                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final house = houses.firstWhere((h) => h.id == selectedHouseId);

                _addTenant(
                  TenantData(
                    id: id,
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    houseId: house.id,
                    houseName: house.name,
                    rentAmount:
                        double.tryParse(rentCtrl.text) ?? house.rentPrice,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 365)),
                    status: 'Active',
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Ongeza'),
            ),
          ],
        );
      },
    );
  }

  void _showRecordPaymentForm() {
    if (tenants.isEmpty) {
      _showError("Hakuna wapangaji. Ongeza mpangaji kwanza.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String selectedTenantId = tenants.first.id;
        final amountCtrl = TextEditingController();
        final monthCtrl = TextEditingController(text: _getCurrentMonth());

        return AlertDialog(
          title: const Text('Andika Malipo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedTenantId,
                  items: tenants
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            "${t.name} - TZS ${t.rentAmount.toInt()}",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedTenantId = v ?? selectedTenantId,
                  decoration: const InputDecoration(
                    labelText: 'Chagua Mpangaji',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kiasi (TZS)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mwezi (e.g. Januari 2024)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () {
                final tenant = tenants.firstWhere(
                  (t) => t.id == selectedTenantId,
                );
                final amount =
                    double.tryParse(amountCtrl.text) ?? tenant.rentAmount;

                if (amount <= 0) {
                  _showError("Tafadhali weka kiasi sahihi");
                  return;
                }

                final id = DateTime.now().millisecondsSinceEpoch.toString();
                _recordPayment(
                  PaymentData(
                    id: id,
                    tenantName: tenant.name,
                    tenantId: tenant.id,
                    amount: amount,
                    date: DateTime.now(),
                    status: 'Pending',
                    month: monthCtrl.text.isNotEmpty
                        ? monthCtrl.text
                        : _getCurrentMonth(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Andika'),
            ),
          ],
        );
      },
    );
  }

  void _showMaintenanceForm() {
    if (tenants.isEmpty && houses.isEmpty) {
      _showError("Hakuna wapangaji au nyumba. Ongeza kwanza.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String selectedTenantId = tenants.isNotEmpty ? tenants.first.id : '';
        String selectedHouseId = houses.isNotEmpty ? houses.first.id : '';
        final issueCtrl = TextEditingController();
        String priority = 'Medium';

        return AlertDialog(
          title: const Text('Omba Matengenezo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tenants.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedTenantId,
                    items: tenants
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedTenantId = v ?? selectedTenantId,
                    decoration: const InputDecoration(
                      labelText: 'Mpangaji (Si lazima)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
                if (houses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedHouseId,
                    items: houses
                        .map(
                          (h) => DropdownMenuItem(
                            value: h.id,
                            child: Text(h.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedHouseId = v ?? selectedHouseId,
                    decoration: const InputDecoration(
                      labelText: 'Nyumba',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: issueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tatizo/Uharibifu',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  items: ['Low', 'Medium', 'High']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => priority = v ?? priority,
                  decoration: const InputDecoration(
                    labelText: 'Kipaumbele',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () {
                if (issueCtrl.text.isEmpty) {
                  _showError("Tafadhali elezea tatizo");
                  return;
                }

                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final tenant = tenants.isNotEmpty
                    ? tenants.firstWhere(
                        (t) => t.id == selectedTenantId,
                        orElse: () => tenants.first,
                      )
                    : null;
                final house = houses.isNotEmpty
                    ? houses.firstWhere(
                        (h) => h.id == selectedHouseId,
                        orElse: () => houses.first,
                      )
                    : null;

                _submitMaintenanceRequest(
                  MaintenanceData(
                    id: id,
                    tenantName: tenant?.name ?? 'Mpangaji',
                    houseName: house?.name ?? 'Nyumba',
                    issue: issueCtrl.text,
                    priority: priority,
                    status: 'Inasubiri',
                    date: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Tuma'),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) {
        final messageCtrl = TextEditingController(
          text: 'Kumbuka kulipa kodi ya mwezi huu!',
        );

        return AlertDialog(
          title: const Text('Tuma Tangazo'),
          content: TextField(
            controller: messageCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Andika ujumbe wa tangazo...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () {
                _sendBulkNotification(messageCtrl.text);
                Navigator.pop(context);
              },
              child: const Text('Tuma'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Vitendo Haraka",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionItem(
                  'Nyumba Mpya',
                  Icons.add_home_rounded,
                  Colors.blue,
                  _showAddHouseForm,
                ),
                _buildQuickActionItem(
                  'Wapangaji',
                  Icons.person_add_rounded,
                  Colors.green,
                  _showAddTenantForm,
                ),
                _buildQuickActionItem(
                  'Malipo',
                  Icons.payment_rounded,
                  Colors.orange,
                  _showRecordPaymentForm,
                ),
                _buildQuickActionItem(
                  'Matengenezo',
                  Icons.handyman_rounded,
                  Colors.purple,
                  _showMaintenanceForm,
                ),
                _buildQuickActionItem(
                  'Taarifa',
                  Icons.analytics_rounded,
                  Colors.red,
                  () => setState(() => _currentIndex = 4),
                ),
                _buildQuickActionItem(
                  'Arifa',
                  Icons.notifications_rounded,
                  Colors.amber,
                  _showNotifications,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showRenewContractDialog(TenantData tenant) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate:
          tenant.endDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (newDate != null) {
      _renewTenantContract(tenant.id, newDate);
    }
  }

  void _showRentIncreaseDialog(TenantData tenant) {
    final rentCtrl = TextEditingController(text: tenant.rentAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ongeza Kodi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mpangaji: ${tenant.name}'),
            const SizedBox(height: 12),
            TextField(
              controller: rentCtrl,
              decoration: const InputDecoration(
                labelText: 'Kodi Mpya (TZS)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'Kodi ya sasa: TZS ${tenant.rentAmount.toInt()}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRent =
                  double.tryParse(rentCtrl.text) ?? tenant.rentAmount;
              _sendRentIncreaseNotice(tenant.id, newRent);
              Navigator.pop(context);
            },
            child: const Text('Tuma Ilani'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadHousesFromAPI();
    _showSuccessMessage("Data imepakiwa upya");
  }
}

// ============ DATA MODELS ============
class TenantData {
  String id;
  String name;
  String phone;
  String houseId;
  String houseName;
  double rentAmount;
  DateTime startDate;
  DateTime? endDate;
  String status;

  TenantData({
    required this.id,
    required this.name,
    required this.phone,
    required this.houseId,
    required this.houseName,
    required this.rentAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
  });
}

class PaymentData {
  String id;
  String tenantId;
  String tenantName;
  double amount;
  DateTime date;
  String status;
  String month;

  PaymentData({
    required this.id,
    required this.tenantName,
    required this.amount,
    required this.date,
    required this.status,
    required this.month,
    required this.tenantId,
  });
}

class MaintenanceData {
  String id;
  String tenantName;
  String houseName;
  String issue;
  String priority;
  String status;
  DateTime date;
  String? assignedTo;

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

class ChartData {
  final String month;
  final double value;

  ChartData(this.month, this.value);
}
