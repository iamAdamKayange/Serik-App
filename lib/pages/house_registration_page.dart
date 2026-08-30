import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/house_data.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/pages/landlord_verification_page.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/widgets/advanced_location_picker.dart';
import 'package:serik/widgets/mapbox_location_picker.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:serik/config/map_config.dart';

class HouseRegistrationForm extends StatefulWidget {
  final Function(HouseData?)? onHouseAdded;
  final HouseData? existingHouse;

  const HouseRegistrationForm({
    super.key,
    this.onHouseAdded,
    this.existingHouse,
  });

  @override
  State<HouseRegistrationForm> createState() => _HouseRegistrationFormState();
}

class _HouseRegistrationFormState extends State<HouseRegistrationForm> {
  static const String _draftStorageKey = 'house_registration_draft_v1';
  final _formKey = GlobalKey<FormState>();
  Timer? _draftSaveDebounce;
  bool _restoringDraft = false;

  // Controllers
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _rentPriceController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _locationDescriptionController =
      TextEditingController();
  final TextEditingController _houseNameController = TextEditingController();
  final TextEditingController _nearbyAmenitiesController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _customBedroomController =
      TextEditingController();

  // Image and video handling
  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingHouse != null) {
      _loadHouseDataForEdit(widget.existingHouse!);
    } else {
      _restoreDraft();
    }
  }

  void _scheduleDraftSave() {
    if (widget.existingHouse != null || _restoringDraft) return;
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 600), _saveDraft);
  }

  Future<void> _restoreDraft() async {
    try {
      _restoringDraft = true;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftStorageKey);
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;

      setState(() {
        _brandNameController.text = data['brandName']?.toString() ?? '';
        _houseNameController.text = data['houseName']?.toString() ?? '';
        _houseNumberController.text = data['houseNumber']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _altPhoneController.text = data['altPhone']?.toString() ?? '';
        _rentPriceController.text = data['rentPrice']?.toString() ?? '';
        _depositController.text = data['deposit']?.toString() ?? '';
        _locationDescriptionController.text =
            data['locationDescription']?.toString() ?? '';
        _nearbyAmenitiesController.text =
            data['nearbyAmenities']?.toString() ?? '';
        _descriptionController.text = data['description']?.toString() ?? '';
        _customBedroomController.text =
            data['customBedrooms']?.toString() ?? '';
        _selectedHouseType =
            data['selectedHouseType']?.toString() ?? _selectedHouseType;
        _selectedBedrooms =
            int.tryParse(data['selectedBedrooms']?.toString() ?? '') ??
            _selectedBedrooms;
        _useCustomBedrooms = data['useCustomBedrooms'] == true;
        _hasCeiling = data['hasCeiling'] == true;
        _hasAluminium = data['hasAluminium'] == true;
        _hasCeilingBoard = data['hasCeilingBoard'] == true;
        _hasTiles = data['hasTiles'] == true;
        _hasFence = data['hasFence'] == true;
        _isSelfContainer = data['isSelfContainer'] != false;
        _hasPrivateBathroom = data['hasPrivateBathroom'] != false;
        _hasPrivateToilet = data['hasPrivateToilet'] != false;
        _hasPrivateKitchen = data['hasPrivateKitchen'] != false;
        _isSharedBathroom = data['isSharedBathroom'] == true;
        _isSharedToilet = data['isSharedToilet'] == true;
        _isSharedKitchen = data['isSharedKitchen'] == true;
        _waterIncluded = data['waterIncluded'] == true;
        _electricityIncluded = data['electricityIncluded'] == true;
        _internetIncluded = data['internetIncluded'] == true;
        _selectedRegion = data['region']?.toString() ?? '';
        _selectedDistrict = data['district']?.toString() ?? '';
        _selectedDivision = data['division']?.toString() ?? '';
        _selectedWard = data['ward']?.toString() ?? '';
        _selectedVillage = data['village']?.toString() ?? '';
        _selectedStreet = data['street']?.toString() ?? '';

        final location = data['selectedLocation'];
        if (location is Map<String, dynamic>) {
          final lat = (location['lat'] as num?)?.toDouble();
          final lng = (location['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _selectedLocation = gmap.LatLng(lat, lng);
          }
        }

        final imagePaths =
            (data['selectedImages'] as List?)?.cast<String>() ?? [];
        final videoPaths =
            (data['selectedVideos'] as List?)?.cast<String>() ?? [];
        _selectedImages
          ..clear()
          ..addAll(
            imagePaths
                .where((path) => File(path).existsSync())
                .map((path) => XFile(path)),
          );
        _selectedVideos
          ..clear()
          ..addAll(
            videoPaths
                .where((path) => File(path).existsSync())
                .map((path) => XFile(path)),
          );
      });
    } catch (e) {
      debugPrint('Draft restore failed: $e');
    } finally {
      _restoringDraft = false;
    }
  }

  Future<void> _saveDraft() async {
    if (widget.existingHouse != null || _restoringDraft) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = <String, dynamic>{
        'brandName': _brandNameController.text,
        'houseName': _houseNameController.text,
        'houseNumber': _houseNumberController.text,
        'phone': _phoneController.text,
        'altPhone': _altPhoneController.text,
        'rentPrice': _rentPriceController.text,
        'deposit': _depositController.text,
        'locationDescription': _locationDescriptionController.text,
        'nearbyAmenities': _nearbyAmenitiesController.text,
        'description': _descriptionController.text,
        'customBedrooms': _customBedroomController.text,
        'selectedHouseType': _selectedHouseType,
        'selectedBedrooms': _selectedBedrooms,
        'useCustomBedrooms': _useCustomBedrooms,
        'hasCeiling': _hasCeiling,
        'hasAluminium': _hasAluminium,
        'hasCeilingBoard': _hasCeilingBoard,
        'hasTiles': _hasTiles,
        'hasFence': _hasFence,
        'isSelfContainer': _isSelfContainer,
        'hasPrivateBathroom': _hasPrivateBathroom,
        'hasPrivateToilet': _hasPrivateToilet,
        'hasPrivateKitchen': _hasPrivateKitchen,
        'isSharedBathroom': _isSharedBathroom,
        'isSharedToilet': _isSharedToilet,
        'isSharedKitchen': _isSharedKitchen,
        'waterIncluded': _waterIncluded,
        'electricityIncluded': _electricityIncluded,
        'internetIncluded': _internetIncluded,
        'region': _selectedRegion,
        'district': _selectedDistrict,
        'division': _selectedDivision,
        'ward': _selectedWard,
        'village': _selectedVillage,
        'street': _selectedStreet,
        'selectedLocation': _selectedLocation == null
            ? null
            : {
                'lat': _selectedLocation!.latitude,
                'lng': _selectedLocation!.longitude,
              },
        'selectedImages': _selectedImages.map((file) => file.path).toList(),
        'selectedVideos': _selectedVideos.map((file) => file.path).toList(),
      };
      await prefs.setString(_draftStorageKey, jsonEncode(draft));
    } catch (e) {
      debugPrint('Draft save failed: $e');
    }
  }

  // ignore: unused_element
  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftStorageKey);
    } catch (e) {
      debugPrint('Draft clear failed: $e');
    }
  }

  void _loadHouseDataForEdit(HouseData house) {
    _brandNameController.text = house.firstName;
    _houseNameController.text = house.name;
    _houseNumberController.text = house.lastName;
    _phoneController.text = house.phone;
    _altPhoneController.text = ''; // API doesn't have altPhone, leave empty
    _rentPriceController.text = house.rentPrice.toString();
    _depositController.text = house.depositAmount?.toString() ?? '';
    _locationDescriptionController.text = house.address;
    _descriptionController.text = house.description;
    _nearbyAmenitiesController.text = house.nearbyAmenities;

    // Booleans
    _waterIncluded = house.waterIncluded;
    _electricityIncluded = house.electricityIncluded;
    _internetIncluded = house.internetIncluded;
    _hasCeiling = house.hasCeiling;
    _hasAluminium = house.hasAluminium;
    _hasCeilingBoard = house.hasCeilingBoard;
    _hasTiles = house.hasTiles;
    _hasFence = house.hasFence;
    _isSelfContainer = house.layoutType == HouseLayoutType.selfContainer;
    _hasPrivateBathroom = house.hasPrivateBathroom;
    _hasPrivateToilet = house.hasPrivateToilet;
    _hasPrivateKitchen = house.hasPrivateKitchen;
    _isSharedBathroom = house.isSharedBathroom;
    _isSharedToilet = house.isSharedToilet;
    _isSharedKitchen = house.isSharedKitchen;

    // Location hierarchy
    _selectedRegion = house.region;
    _selectedDistrict = house.district;
    _selectedDivision = house.division;
    _selectedWard = house.ward;
    _selectedVillage = house.village;
    _selectedStreet = house.street;

    // House type
    if (_houseTypes.contains(house.type)) {
      _selectedHouseType = house.type;
    }

    // Bedrooms
    final bedrooms = house.bedrooms;
    if (bedrooms > 6) {
      _useCustomBedrooms = true;
      _selectedBedrooms = bedrooms;
      _customBedroomController.text = bedrooms.toString();
    } else {
      _useCustomBedrooms = false;
      _selectedBedrooms = bedrooms;
    }

    // Location on map
    if (house.latitude != null && house.longitude != null) {
      _selectedLocation = gmap.LatLng(house.latitude!, house.longitude!);
    }
  }

  // Location handling
  gmap.LatLng? _selectedLocation;
  // ignore: unused_field
  String _locationAddress = "";

  // Upload progress details
  double _uploadProgress = 0.0;
  String _currentFileStatus = "Inaandaa...";
  int _uploadedCount = 0;
  int _totalFiles = 0;

  // Step and loading states
  int _currentStep = 0;
  bool _isSubmitting = false;

  // House details
  String _selectedHouseType = 'Nyumba ya Kawaida';
  int _selectedBedrooms = 1;
  bool _useCustomBedrooms = false;

  // TOGGLE FEATURES FOR HOUSE
  bool _hasCeiling = false;
  bool _hasAluminium = false;
  bool _hasCeilingBoard = false;
  bool _hasTiles = false;
  bool _hasFence = false;

  // TOGGLE FEATURES FOR LAYOUT
  bool _isSelfContainer = true;
  bool _hasPrivateBathroom = true;
  bool _hasPrivateToilet = true;
  bool _hasPrivateKitchen = true;
  bool _isSharedBathroom = false;
  bool _isSharedToilet = false;
  bool _isSharedKitchen = false;

  // Amenities
  bool _waterIncluded = false;
  bool _electricityIncluded = false;
  bool _internetIncluded = false;

  // Location hierarchy
  String _selectedRegion = '';
  String _selectedDistrict = '';
  String _selectedDivision = '';
  String _selectedWard = '';
  String _selectedVillage = '';
  String _selectedStreet = '';

  final List<String> _houseTypes = [
    'Nyumba ya Kawaida',
    'Apartment',
    'Studio',
    'Mansion',
    'Hostel',
    'Ghorofa',
    'Biashara',
  ];

  // Dynamic colors getters using ThemeProvider
  Color get primaryColor => Provider.of<ThemeProvider>(context).isDarkMode
      ? const Color(0xFF4CAF50)
      : const Color(0xFF2E7D32);

  Color get backgroundColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? const Color(0xFF121212)
      : Colors.white;

  Color get surfaceColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? const Color(0xFF1E1E1E)
      : Colors.white;

  Color get textColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? Colors.white
      : Colors.black87;

  Color get subtextColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? Colors.grey[400]!
      : Colors.grey[600]!;

  Color get inputFillColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? Colors.grey[900]!
      : Colors.grey[50]!;

  Color get borderColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? Colors.grey[800]!
      : Colors.grey[300]!;

  Color get cardBgColor =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode
      ? const Color(0xFF1E1E1E)
      : Colors.white;

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isSubmitting ? _buildLoadingScreen() : _buildForm(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/animations/tick.json",
            height: 150,
            width: 150,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 8,
                  backgroundColor:
                      Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2E7D32),
                  ),
                ),
              ),
              Text(
                "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Inasajiliwa...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _currentFileStatus,
            style: TextStyle(fontSize: 14, color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
              ),
              const SizedBox(width: 8),
              Text(
                "Usajili wa Nyumba",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                "Hatua ${_currentStep + 1}/4",
                style: TextStyle(
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (_currentStep + 1) / 4,
          backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
              ? Colors.grey[800]
              : Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepContent(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goToPreviousStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Nyuma"),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _goToNextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == 3 ? "Maliza Usajili" : "Endelea",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildHouseDetailsStep();
      case 2:
        return _buildImagesStep();
      case 3:
        return _buildPriceAndLocationStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 120,
            child: Lottie.asset(
              "assets/animations/house1.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Taarifa Binafsi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Weka taarifa zako za mawasiliano',
          style: TextStyle(color: subtextColor, fontSize: 16),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _brandNameController,
                label: 'Jina Maarufu',
                icon: Icons.home_rounded,
                onChanged: (_) => _scheduleDraftSave(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr(
                      "Tafadhali weka jina maarufu la nyumba",
                      en: "Please enter the popular name of the house",
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _houseNameController,
                label: 'Jina la Mwenye Nyumba',
                icon: Icons.apartment_rounded,
                onChanged: (_) => _scheduleDraftSave(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr(
                      "Tafadhali weka jina mwenye nyumba",
                      en: "Please enter the landlord name",
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _houseNumberController,
                label: 'Namba ya Nyumba',
                icon: Icons.numbers_rounded,
                onChanged: (_) => _scheduleDraftSave(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr(
                      "Tafadhali weka namba ya nyumba",
                      en: "Please enter the house number",
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Namba ya Simu',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _scheduleDraftSave(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr(
                      "Tafadhali weka namba yako ya simu",
                      en: "Please enter your phone number",
                    );
                  }
                  if (value.length < 10) {
                    return context.tr(
                      "Namba ya simu si sahihi",
                      en: "Invalid phone number",
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _altPhoneController,
                label: 'Namba Mbadala ya Simu (Si lazima)',
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _scheduleDraftSave(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subtextColor),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        filled: true,
        fillColor: inputFillColor,
      ),
      validator: validator,
    );
  }

  Widget _buildHouseDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 120,
            child: Lottie.asset(
              "assets/animations/house2.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Maelezo ya Nyumba',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Weka maelezo kamili ya nyumba unayopanga',
          style: TextStyle(color: subtextColor, fontSize: 16),
        ),
        const SizedBox(height: 32),
        Column(
          children: [
            // AINA YA NYUMBA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
                color: inputFillColor,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedHouseType,
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: subtextColor,
                  ),
                  isExpanded: true,
                  style: TextStyle(fontSize: 16, color: textColor),
                  dropdownColor: surfaceColor,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedHouseType = newValue!;
                    });
                    _scheduleDraftSave();
                  },
                  items: _houseTypes.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // IDADI YA VYUMBA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
                color: inputFillColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bed_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Idadi ya Vyumba vya Kulala',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...List.generate(6, (index) {
                        final bedrooms = index + 1;
                        return ChoiceChip(
                          label: Text('$bedrooms'),
                          selected:
                              !_useCustomBedrooms &&
                              _selectedBedrooms == bedrooms,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _useCustomBedrooms = false;
                                _selectedBedrooms = bedrooms;
                                _customBedroomController.clear();
                              }
                            });
                            _scheduleDraftSave();
                          },
                          selectedColor: primaryColor,
                          backgroundColor: inputFillColor,
                          labelStyle: TextStyle(
                            color:
                                !_useCustomBedrooms &&
                                    _selectedBedrooms == bedrooms
                                ? Colors.white
                                : textColor,
                          ),
                        );
                      }),
                      ChoiceChip(
                        label: const Text('Zaidi ya 6'),
                        selected: _useCustomBedrooms,
                        onSelected: (selected) {
                          setState(() {
                            _useCustomBedrooms = selected;
                            if (!selected &&
                                _customBedroomController.text.isNotEmpty) {
                              _selectedBedrooms =
                                  int.tryParse(_customBedroomController.text) ??
                                  7;
                            }
                          });
                          _scheduleDraftSave();
                        },
                        selectedColor: primaryColor,
                        backgroundColor: inputFillColor,
                        labelStyle: TextStyle(
                          color: _useCustomBedrooms ? Colors.white : textColor,
                        ),
                      ),
                    ],
                  ),
                  if (_useCustomBedrooms) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customBedroomController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Weka idadi ya vyumba',
                        labelStyle: TextStyle(color: subtextColor),
                        hintText: 'Mfano: 7, 8, 10',
                        hintStyle: TextStyle(color: subtextColor),
                        prefixIcon: Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _selectedBedrooms = int.tryParse(value) ?? 7;
                        }
                        _scheduleDraftSave();
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chagua idadi ya vyumba vya kulala. Kama idadi ni zaidi ya 6, chagua "Zaidi ya 6" na uweke idadi mwenyewe.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AINA YA MPANGILIO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
                color: inputFillColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aina ya Mpangilio',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildToggleCard(
                          title: 'Self Container',
                          subtitle: 'Vyumba vyake ndani',
                          isSelected: _isSelfContainer,
                          onTap: () {
                            setState(() {
                              _isSelfContainer = true;
                              _hasPrivateBathroom = true;
                              _hasPrivateToilet = true;
                              _hasPrivateKitchen = true;
                              _isSharedBathroom = false;
                              _isSharedToilet = false;
                              _isSharedKitchen = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildToggleCard(
                          title: 'Shared',
                          subtitle: 'Bafu/Jiko la kushiriki',
                          isSelected: !_isSelfContainer,
                          onTap: () {
                            setState(() {
                              _isSelfContainer = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!_isSelfContainer) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Vifaa vinavyoshirikishwa:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Bafu'),
                          selected: _isSharedBathroom,
                          onSelected: (val) =>
                              setState(() => _isSharedBathroom = val),
                          selectedColor: primaryColor.withAlpha(51),
                          backgroundColor: inputFillColor,
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(color: textColor),
                        ),
                        FilterChip(
                          label: const Text('Choo'),
                          selected: _isSharedToilet,
                          onSelected: (val) =>
                              setState(() => _isSharedToilet = val),
                          selectedColor: primaryColor.withAlpha(51),
                          backgroundColor: inputFillColor,
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(color: textColor),
                        ),
                        FilterChip(
                          label: const Text('Jikoni'),
                          selected: _isSharedKitchen,
                          onSelected: (val) =>
                              setState(() => _isSharedKitchen = val),
                          selectedColor: primaryColor.withAlpha(51),
                          backgroundColor: inputFillColor,
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // VIPENGELE VYA NYUMBA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
                color: inputFillColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Vipengele vya Nyumba',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Washa vitu vilivyopo kwenye nyumba yako:',
                    style: TextStyle(color: subtextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildFeatureToggle(
                        icon: Icons.roofing,
                        label: 'Fansi (Ceiling)',
                        value: _hasCeiling,
                        onChanged: (val) => setState(() => _hasCeiling = val),
                      ),
                      _buildFeatureToggle(
                        icon: Icons.window_rounded,
                        label: 'Aluminiam Windows',
                        value: _hasAluminium,
                        onChanged: (val) => setState(() => _hasAluminium = val),
                      ),
                      _buildFeatureToggle(
                        icon: Icons.grid_on_rounded,
                        label: 'Ceiling Board',
                        value: _hasCeilingBoard,
                        onChanged: (val) =>
                            setState(() => _hasCeilingBoard = val),
                      ),
                      _buildFeatureToggle(
                        icon: Icons.square_foot_rounded,
                        label: 'Tiles',
                        value: _hasTiles,
                        onChanged: (val) => setState(() => _hasTiles = val),
                      ),
                      _buildFeatureToggle(
                        icon: Icons.fence_rounded,
                        label: 'Fence / Uzio',
                        value: _hasFence,
                        onChanged: (val) => setState(() => _hasFence = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr(
                              'Bonyeza kuwasha/kuzima kipengele chochote kilichopo nyumbani kwako',
                              en: 'Tap to turn on/off any features in your home',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MAELEZO YA ZIADA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
                color: inputFillColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Maelezo ya Ziada',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Andika maelezo ya ziada kuhusu nyumba...',
                      hintStyle: TextStyle(color: subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: inputFillColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureToggle({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        decoration: BoxDecoration(
          color: value ? primaryColor.withAlpha(26) : inputFillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? primaryColor : borderColor,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: value ? primaryColor : subtextColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: value ? primaryColor : subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(26) : inputFillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primaryColor : subtextColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: subtextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Images and Videos
  Widget _buildImagesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 120,
            child: Lottie.asset(
              "assets/animations/camera.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Picha za Nyumba',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pakia picha angalau 3 za nyumba kutoka pembe tofauti',
          style: TextStyle(color: subtextColor, fontSize: 16),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor),
                    borderRadius: BorderRadius.circular(12),
                    color: primaryColor.withAlpha(26),
                  ),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    size: 32,
                    color: primaryColor,
                  ),
                ),
              );
            } else {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImages[index - 1].path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index - 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickVideos,
          icon: const Icon(Icons.video_collection_rounded),
          label: const Text('Ongeza Video'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedVideos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedVideos
                .map(
                  (video) => Chip(
                    label: Text(
                      video.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () =>
                        setState(() => _selectedVideos.remove(video)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: primaryColor.withAlpha(51),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _selectedImages.length >= 3
                ? primaryColor.withAlpha(26)
                : Colors.orange.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedImages.length >= 3 ? primaryColor : Colors.orange,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _selectedImages.length >= 3 ? Icons.check_circle : Icons.info,
                color: _selectedImages.length >= 3
                    ? primaryColor
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedImages.length >= 3
                      ? "Picha ${_selectedImages.length} zimepakwa kikamilifu"
                      : "Picha ${_selectedImages.length}/3 - Pakia angalau picha 3",
                  style: TextStyle(
                    color: _selectedImages.length >= 3
                        ? primaryColor
                        : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedVideos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "Video ${_selectedVideos.length} zimechaguliwa",
              style: TextStyle(color: primaryColor, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceAndLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 110,
            child: Lottie.asset(
              "assets/animations/location.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bei na Eneo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Weka bei na eneo kamili la nyumba',
          style: TextStyle(color: subtextColor, fontSize: 16),
        ),
        const SizedBox(height: 32),
        Column(
          children: [
            Card(
              color: cardBgColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Maelezo ya Bei',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _rentPriceController,
                      label: 'Kodi ya Mwezi (TZS)',
                      icon: Icons.money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr(
                            "Tafadhali weka bei",
                            en: "Please enter the price",
                          );
                        }
                        if (double.tryParse(value) == null) {
                          return context.tr(
                            "Weka namba sahihi",
                            en: "Enter a valid number",
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _depositController,
                      label: 'Deposit / Kibali (TZS) - Si lazima',
                      icon: Icons.savings_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Yaliyojumuishwa kwenye kodi:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('💧 Maji'),
                          selected: _waterIncluded,
                          onSelected: (val) =>
                              setState(() => _waterIncluded = val),
                          selectedColor: primaryColor.withAlpha(51),
                          backgroundColor: inputFillColor,
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(color: textColor),
                        ),
                        FilterChip(
                          label: const Text('⚡ Umeme'),
                          selected: _electricityIncluded,
                          onSelected: (val) =>
                              setState(() => _electricityIncluded = val),
                          selectedColor: primaryColor.withAlpha(51),
                          backgroundColor: inputFillColor,
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(color: textColor),
                        ),
                        FilterChip(
                          label: const Text('🌐 Internet'),
                          selected: _internetIncluded,
                          onSelected: (val) =>
                              setState(() => _internetIncluded = val),
                          selectedColor: primaryColor.withAlpha(51),
                          backgroundColor: inputFillColor,
                          checkmarkColor: primaryColor,
                          labelStyle: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nearbyAmenitiesController,
                      label: 'Vitu vilivyo karibu (Shule, Hospitali, Duka)',
                      icon: Icons.place_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: cardBgColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Taarifa za Eneo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Switch between CSV picker and Mapbox picker based on config
                    if (MapConfig.useMapbox)
                      MapboxLocationPicker(
                        onChanged: (location) {
                          if (location != null) {
                            setState(() {
                              _locationDescriptionController.text = 
                                '${location.latitude}, ${location.longitude}';
                            });
                          }
                        },
                      )
                    else
                      AdvancedLocationPicker(
                        onLocationSelected:
                            (
                              fullAddress,
                              region,
                              district,
                              division,
                              ward,
                              village,
                              street,
                            ) {
                              setState(() {
                                _selectedRegion = region;
                                _selectedDistrict = district;
                                _selectedDivision = division;
                                _selectedWard = ward;
                                _selectedVillage = village;
                                _selectedStreet = street;
                                _locationDescriptionController.text = fullAddress;
                              });
                            },
                      ),
                    if (_selectedRegion.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Anwani Kamili:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _locationDescriptionController.text,
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: cardBgColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🗺️ Chagua Eneo kwenye Ramani',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedLocation == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_searching,
                                    size: 50,
                                    color: subtextColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr(
                                      "Bonyeza kwenye ramani kuchagua eneo",
                                      en: "Tap on the map to select location",
                                    ),
                                    style: TextStyle(color: subtextColor),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _getCurrentLocation,
                                    icon: const Icon(Icons.my_location_rounded),
                                    label: const Text(
                                      "Tumia Eneo Langu la Sasa",
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: gmap.GoogleMap(
                                initialCameraPosition: gmap.CameraPosition(
                                  target: _selectedLocation!,
                                  zoom: 17,
                                ),
                                markers: {
                                  gmap.Marker(
                                    markerId: const gmap.MarkerId("nyumba"),
                                    position: _selectedLocation!,
                                    infoWindow: gmap.InfoWindow(
                                      title: "Eneo la Nyumba",
                                      snippet: _selectedStreet.isNotEmpty
                                          ? _selectedStreet
                                          : _selectedWard,
                                    ),
                                  ),
                                },
                                onTap: _selectLocation,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _goToNextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitForm();
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.maybePop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        if (_useCustomBedrooms && _customBedroomController.text.isEmpty) {
          _showFeedback(
            context.tr(
              "Tafadhali weka idadi ya vyumba",
              en: "Please enter the number of rooms",
            ),
            isError: true,
            icon: Icons.warning_rounded,
          );
          return false;
        }
        if (_useCustomBedrooms) {
          final customValue = int.tryParse(_customBedroomController.text);
          if (customValue == null || customValue < 1) {
            _showFeedback(
              context.tr(
                "Tafadhali weka idadi sahihi ya vyumba",
                en: "Please enter a valid number of rooms",
              ),
              isError: true,
              icon: Icons.warning_rounded,
            );
            return false;
          }
        }
        return true;
      case 2:
        if (_selectedImages.length < 3) {
          _showFeedback(
            context.tr(
              "Tafadhali pakia angalau picha tatu",
              en: "Please upload at least three photos",
            ),
            isError: true,
            icon: Icons.photo_library_outlined,
          );
          return false;
        }
        return true;
      case 3:
        if (_rentPriceController.text.isEmpty) {
          _showFeedback(
            context.tr(
              "Tafadhali weka bei ya kukodisha",
              en: "Please enter the rental price",
            ),
            isError: true,
            icon: Icons.payments_outlined,
          );
          return false;
        }
        if (_selectedRegion.isEmpty) {
          _showFeedback(
            context.tr(
              "Tafadhali chagua Mkoa",
              en: "Please select a Region",
            ),
            isError: true,
            icon: Icons.location_city_outlined,
          );
          return false;
        }
        if (_selectedDistrict.isEmpty) {
          _showFeedback(
            context.tr(
              "Tafadhali chagua Wilaya",
              en: "Please select a District",
            ),
            isError: true,
            icon: Icons.map_outlined,
          );
          return false;
        }
        if (_selectedWard.isEmpty) {
          _showFeedback(
            context.tr(
              "Tafadhali chagua Kata",
              en: "Please select a Ward",
            ),
            isError: true,
            icon: Icons.place_outlined,
          );
          return false;
        }
        if (_selectedStreet.isEmpty) {
          _showFeedback(
            context.tr(
              "Tafadhali weka jina la Mtaa",
              en: "Please enter the street name",
            ),
            isError: true,
            icon: Icons.edit_location_alt_outlined,
          );
          return false;
        }
        if (_selectedLocation == null) {
          _showFeedback(
            context.tr(
              "Tafadhali chagua eneo la nyumba kwenye ramani",
              en: "Please select the house location on the map",
            ),
            isError: true,
            icon: Icons.map_rounded,
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (!mounted) return;
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        context.tr(
          "Hitilafu ya kupakua picha: $e",
          en: "Error uploading photos: $e",
        ),
        isError: true,
        icon: Icons.photo_library_outlined,
      );
    }
  }

  Future<void> _pickVideos() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final sizeInBytes = await video.length();
        if (!mounted) return;
        final sizeInMB = sizeInBytes / (1024 * 1024);
        if (sizeInMB > 50) {
          _showFeedback(
            'Video haipaswi kuzidi MB 50',
            isError: true,
            icon: Icons.videocam_off_rounded,
          );
          return;
        }
        setState(() {
          _selectedVideos.add(video);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        context.tr(
          'Hitilafu kuchagua video: $e',
          en: 'Error selecting video: $e',
        ),
        isError: true,
        icon: Icons.video_collection_rounded,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showFeedback(
          "Huduma ya eneo haijawezeshwa",
          isError: true,
          icon: Icons.location_off_rounded,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          _showFeedback(
            "Ruhusa ya eneo imekataliwa",
            isError: true,
            icon: Icons.location_off_rounded,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showFeedback(
          "Ruhusa ya eneo imekataliwa kabisa",
          isError: true,
          icon: Icons.location_off_rounded,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final location = gmap.LatLng(position.latitude, position.longitude);
      _selectLocation(location);
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        context.tr(
          "Hitilafu ya kupata eneo: $e",
          en: "Error getting location: $e",
        ),
        isError: true,
        icon: Icons.location_searching_rounded,
      );
    }
  }

  void _selectLocation(gmap.LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationAddress =
          "${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}";
    });
  }

  void _showFeedback(
    String message, {
    bool isError = false,
    IconData icon = Icons.info_outline_rounded,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isError ? const Color(0xFFD32F2F) : primaryColor,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationReminder() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFF9800),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      "Bado hujaverified! Tafadhali jithibitishe ili kuweka nyumba.",
                      en: "Not verified yet! Please verify yourself to list houses.",
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      "Piga +255 123 456 789 kwa msaada wa verification",
                      en: "Call +255 123 456 789 for verification assistance",
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.tr("Jithibitishe", en: "Verify"),
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LandlordVerificationPage()),
            );
          },
        ),
      ),
    );
  }

  // ==================== VIDEO THUMBNAIL GENERATION ====================

  /// Generate thumbnails for all selected videos
  Future<List<String>> _generateAndUploadThumbnails(List<XFile> videos) async {
    List<String> thumbnailUrls = [];

    for (final video in videos) {
      try {
        _currentFileStatus = "Inatengeneza thumbnail ya ${video.name}...";
        setState(() {});

        // Generate thumbnail from video
        final File thumbnailFile = await VideoCompress.getFileThumbnail(
          video.path,
          quality: 50, // Good quality
        );

        if (thumbnailFile.existsSync()) {
          // Upload thumbnail to backend
          final XFile thumbnailXFile = XFile(thumbnailFile.path);
          final String? url = await ApiService.uploadThumbnail(thumbnailXFile);

          if (url != null) {
            thumbnailUrls.add(url);
            debugPrint('✅ Thumbnail uploaded: $url');
          }

          // Delete temporary thumbnail file
          try {
            await thumbnailFile.delete();
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('❌ Thumbnail generation failed for ${video.name}: $e');
        // Continue with next video
      }
    }

    return thumbnailUrls;
  }

  // ==================== SUBMIT FORM ====================

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) return;

    // Validation ya token (kama ulivyo nayo)
    final isValid = await ApiService.isLandlordTokenValid();
    if (!isValid) {
      await ApiService.logout();
      if (mounted) {
        _showFeedback(
          context.tr(
            'Tafadhali ingia tena kama Mwenye Nyumba.',
            en: 'Please login again as a Landlord.',
          ),
          isError: true,
          icon: Icons.login_rounded,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
      _uploadedCount = 0;
      _currentFileStatus = "Inaandaa faili...";
    });

    try {
      final isEditing = widget.existingHouse != null;

      List<String> imageUrls = [];
      List<String> videoUrls = [];
      List<String> videoThumbnails = [];

      if (!isEditing ||
          _selectedImages.isNotEmpty ||
          _selectedVideos.isNotEmpty) {
        // Compress videos
        _currentFileStatus = "Inabana video...";
        setState(() {});
        final List<XFile> compressedVideos = await _compressVideosInParallel();

        _currentFileStatus = "Kuandaa faili za kupakia...";
        setState(() {});
        final List<http.MultipartFile> multipartFiles =
            await _prepareMultipartFiles(compressedVideos);
        _totalFiles = multipartFiles.length;
        setState(() => _uploadProgress = 0.1);

        if (multipartFiles.isNotEmpty) {
          _currentFileStatus = "Kupakia media kwenye DigitalOcean Spaces...";
          setState(() {});
          final uploadedFiles = await _uploadFilesInParallel(multipartFiles);

          imageUrls = uploadedFiles
              .where((f) => f['resourceType'] == 'image')
              .map((f) => f['url'] as String)
              .toList();
          videoUrls = uploadedFiles
              .where((f) => f['resourceType'] == 'video')
              .map((f) => f['url'] as String)
              .toList();

          // ✅ GENERATE THUMBNAILS FOR VIDEOS
          if (compressedVideos.isNotEmpty) {
            _currentFileStatus = "Inatengeneza thumbnails za video...";
            setState(() {});
            videoThumbnails = await _generateAndUploadThumbnails(
              compressedVideos,
            );
          }
        }
      }

      // If editing, keep existing media if no new ones added
      if (isEditing) {
        if (imageUrls.isEmpty) {
          imageUrls = widget.existingHouse!.images;
        }
        if (videoUrls.isEmpty) {
          videoUrls = widget.existingHouse!.videos;
        }
        if (videoThumbnails.isEmpty) {
          videoThumbnails = widget.existingHouse!.videoThumbnails;
        }
      }

      setState(() => _uploadProgress = 0.7);
      _currentFileStatus = isEditing
          ? "Inahifadhi mabadiliko..."
          : "Inahifadhi nyumba...";
      setState(() {});

      final houseData = _buildHouseData(imageUrls, videoUrls, videoThumbnails);

      // Check verification status for new house creation
      if (!isEditing) {
        try {
          final verificationStatus = await ApiService.getVerificationStatus();
          if (verificationStatus != null && verificationStatus['canPublish'] != true) {
            _showVerificationReminder();
            _showFeedback(
              context.tr(
                "Lazima uwe verified kama mwenye nyumba kabla ya kuweka nyumba.",
                en: "You must be verified as a landlord before listing houses.",
              ),
              icon: Icons.warning_rounded,
              isError: true,
            );
            return;
          }
        } catch (e) {
          debugPrint('Error checking verification status: $e');
          _showFeedback(
            "Hitilafu kubadilisha status ya verification.",
            icon: Icons.error_rounded,
            isError: true,
          );
          return;
        }
      }

      dynamic result;
      if (isEditing) {
        result = await ApiService.updateHouse(
          widget.existingHouse!.id,
          houseData,
        );
      } else {
        result = await ApiService.createHouse(houseData);
      }

      if (result != null && mounted) {
        final successMsg = isEditing
            ? context.tr("Nyumba imerekebishwa!", en: "House updated!")
            : context.tr("Nyumba imesajiliwa!", en: "House registered!");
        _showFeedback(successMsg, icon: Icons.check_circle_rounded);
        Navigator.pop(context, true);
        if (widget.onHouseAdded != null) {
          widget.onHouseAdded!(null);
        }
      } else {
        throw Exception(
          isEditing 
              ? context.tr("Kurekebisha hakukufaulu", en: "Update failed")
              : context.tr("Kuunda hakukufaulu", en: "Creation failed"),
        );
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        _showFeedback(
          'Hitilafu: $e',
          isError: true,
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<List<XFile>> _compressVideosInParallel() async {
    if (_selectedVideos.isEmpty) return [];
    final List<Future<XFile?>> futures = [];
    for (final video in _selectedVideos) {
      futures.add(_compressSingleVideo(video));
    }
    final results = await Future.wait(futures);
    return results.whereType<XFile>().toList();
  }

  Future<XFile?> _compressSingleVideo(XFile video) async {
    try {
      final bytes = await video.readAsBytes();
      final sizeMB = bytes.length / (1024 * 1024);
      if (sizeMB > 50) throw Exception('Video ${video.name} inazidi MB 50');

      final result = await VideoCompress.compressVideo(
        video.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
      );
      if (result != null && result.file != null) {
        debugPrint(
          '✅ Compressed: ${video.name} -> ${result.file!.lengthSync() / (1024 * 1024)} MB',
        );
        return XFile(result.file!.path);
      }
      return video; // fallback
    } catch (e) {
      debugPrint('Compression failed for ${video.name}: $e');
      return video;
    }
  }

  Future<List<http.MultipartFile>> _prepareMultipartFiles(
    List<XFile> compressedVideos,
  ) async {
    final List<http.MultipartFile> files = [];
    // Add images
    for (final image in _selectedImages) {
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: image.name,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }
    // Add videos
    for (final video in compressedVideos) {
      final bytes = await video.readAsBytes();
      final mimeType = lookupMimeType(video.path) ?? 'video/mp4';
      files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: video.name,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }
    return files;
  }

  Future<List<Map<String, dynamic>>> _uploadFilesInParallel(
    List<http.MultipartFile> files,
  ) async {
    final List<Future<List<Map<String, dynamic>>>> futures = [];
    for (int i = 0; i < files.length; i++) {
      futures.add(_uploadSingleFile(files[i], i));
    }
    final allResults = await Future.wait(futures);
    return allResults.expand((result) => result).toList();
  }

  Future<List<Map<String, dynamic>>> _uploadSingleFile(
    http.MultipartFile file,
    int index,
  ) async {
    setState(() {
      _currentFileStatus = "Inapakia faili ${index + 1}/$_totalFiles...";
    });
    final url = Uri.parse(
      '${ApiService.baseUrl}${ApiService.apiPrefix}/houses/upload-media',
    );
    final token = await ApiService.getToken();
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(file);
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _uploadedCount++;
        _uploadProgress = 0.2 + (0.5 * (_uploadedCount / _totalFiles));
      });
      return List<Map<String, dynamic>>.from(data['files']);
    } else {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }

  Map<String, dynamic> _buildHouseData(
    List<String> imageUrls,
    List<String> videoUrls,
    List<String> videoThumbnails,
  ) {
    return {
      "name": _houseNameController.text,
      "status": "Inapatikana",
      "type": _selectedHouseType,
      "bedrooms": _selectedBedrooms,
      "description": _descriptionController.text,
      "firstName": _brandNameController.text,
      "lastName": _houseNumberController.text,
      "phone": _phoneController.text,
      "rentPrice": double.parse(_rentPriceController.text),
      "locationAddress": _locationDescriptionController.text,
      "latitude": _selectedLocation?.latitude,
      "longitude": _selectedLocation?.longitude,
      "region": _selectedRegion,
      "district": _selectedDistrict,
      "division": _selectedDivision,
      "ward": _selectedWard,
      "village": _selectedVillage,
      "street": _selectedStreet,
      "depositAmount": _depositController.text.isNotEmpty
          ? double.parse(_depositController.text)
          : null,
      "waterIncluded": _waterIncluded,
      "electricityIncluded": _electricityIncluded,
      "internetIncluded": _internetIncluded,
      "nearbyAmenities": _nearbyAmenitiesController.text,
      "hasCeiling": _hasCeiling,
      "hasAluminium": _hasAluminium,
      "hasCeilingBoard": _hasCeilingBoard,
      "hasTiles": _hasTiles,
      "hasFence": _hasFence,
      "layoutType": _isSelfContainer ? "self_container" : "shared",
      "hasPrivateBathroom": _hasPrivateBathroom,
      "hasPrivateToilet": _hasPrivateToilet,
      "hasPrivateKitchen": _hasPrivateKitchen,
      "isSharedBathroom": _isSharedBathroom,
      "isSharedToilet": _isSharedToilet,
      "isSharedKitchen": _isSharedKitchen,
      "imageUrls": imageUrls,
      "videoUrls": videoUrls,
      "videoThumbnails": videoThumbnails, // ✅ SASA INATUMWA
    };
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _houseNumberController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _rentPriceController.dispose();
    _depositController.dispose();
    _locationDescriptionController.dispose();
    _houseNameController.dispose();
    _nearbyAmenitiesController.dispose();
    _descriptionController.dispose();
    _customBedroomController.dispose();
    super.dispose();
  }
}
