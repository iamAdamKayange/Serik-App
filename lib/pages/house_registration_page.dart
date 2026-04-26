// lib/pages/house_registration_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:lottie/lottie.dart';
import 'package:serkapp/model/house_data.dart';
import 'package:serkapp/pages/rental_home_page.dart'; // 🔥 ADDED: ApiService
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/widgets/advanced_location_picker.dart';

class HouseRegistrationForm extends StatefulWidget {
  final Function(HouseData) onHouseAdded;

  const HouseRegistrationForm({super.key, required this.onHouseAdded});

  @override
  State<HouseRegistrationForm> createState() => _HouseRegistrationFormState();
}

class _HouseRegistrationFormState extends State<HouseRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // ========== CONTROLLERS ZA FORM FIELDS ==========
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

  // ========== IMAGE HANDLING ==========
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // ========== LOCATION HANDLING ==========
  gmap.LatLng? _selectedLocation;
  String _locationAddress = "";

  // ========== STEP NA LOADING STATES ==========
  int _currentStep = 0;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  // ========== HOUSE DETAILS ==========
  String _selectedHouseType = 'Nyumba ya Kawaida';
  int _selectedBedrooms = 1;

  // ========== AMENITIES INCLUDED IN RENT ==========
  bool _waterIncluded = false;
  bool _electricityIncluded = false;
  bool _internetIncluded = false;

  // ========== FULL LOCATION HIERARCHY ==========
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            repeat: false,
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
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF2E7D32),
                  ),
                ),
              ),
              Text(
                "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Inasajiliwa...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tafadhali subiri...",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "Usajili wa Nyumba",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              Spacer(),
              Text(
                "Hatua ${_currentStep + 1}/4",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (_currentStep + 1) / 4,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2E7D32)),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepContent(),
                SizedBox(height: 32),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goToPreviousStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: BorderSide(color: const Color(0xFF2E7D32)),
                            minimumSize: Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Nyuma"),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _goToNextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == 3 ? "Maliza Usajili" : "Endelea",
                          style: TextStyle(fontWeight: FontWeight.w600),
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
        SizedBox(height: 20),
        Text(
          'Taarifa Binafsi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Weka taarifa zako za mawasiliano',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _brandNameController,
                decoration: InputDecoration(
                  labelText: 'Jina Maarufu',
                  prefixIcon: Icon(Icons.home_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Tafadhali weka jina maarufu la nyumba";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _houseNameController,
                decoration: InputDecoration(
                  labelText: 'Jina la Mwenye Nyumba',
                  prefixIcon: Icon(Icons.apartment_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Tafadhali weka jina mwenye nyumba";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _houseNumberController,
                decoration: InputDecoration(
                  labelText: 'Namba ya Nyumba',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Tafadhali weka namba ya nyumba";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Namba ya Simu',
                  prefixIcon: Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Tafadhali weka namba yako ya simu";
                  }
                  if (value.length < 10) {
                    return "Namba ya simu si sahihi";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _altPhoneController,
                decoration: InputDecoration(
                  labelText: 'Namba Mbadala ya Simu (Si lazima)',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
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
        SizedBox(height: 20),
        Text(
          'Maelezo ya Nyumba',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Weka maelezo kamili ya nyumba unayopanga',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        SizedBox(height: 32),
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedHouseType,
                  icon: Icon(Icons.arrow_drop_down_rounded),
                  isExpanded: true,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedHouseType = newValue!;
                    });
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
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Idadi ya Vyumba vya Kulala',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(6, (index) {
                      final bedrooms = index + 1;
                      return ChoiceChip(
                        label: Text('$bedrooms'),
                        selected: _selectedBedrooms == bedrooms,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBedrooms = bedrooms;
                          });
                        },
                        selectedColor: const Color(0xFF2E7D32),
                        labelStyle: TextStyle(
                          color: _selectedBedrooms == bedrooms
                              ? Colors.white
                              : Colors.black87,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

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
        SizedBox(height: 20),
        Text(
          'Picha za Nyumba',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Pakia picha angalau 3 za nyumba kutoka pembe tofauti',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                    border: Border.all(color: const Color(0xFF2E7D32)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    size: 32,
                    color: const Color(0xFF2E7D32),
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
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(4),
                        child: Icon(
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
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _selectedImages.length >= 3
                ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedImages.length >= 3
                  ? const Color(0xFF2E7D32)
                  : Colors.orange,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _selectedImages.length >= 3 ? Icons.check_circle : Icons.info,
                color: _selectedImages.length >= 3
                    ? const Color(0xFF2E7D32)
                    : Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedImages.length >= 3
                      ? "Picha ${_selectedImages.length} zimepakwa kikamilifu"
                      : "Picha ${_selectedImages.length}/3 - Pakia angalau picha 3",
                  style: TextStyle(
                    color: _selectedImages.length >= 3
                        ? const Color(0xFF2E7D32)
                        : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
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
            height: 120,
            child: Lottie.asset(
              "assets/animations/location.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Bei, Maelezo na Eneo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Weka bei, maelezo na eneo kamili la nyumba',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        SizedBox(height: 32),
        Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Maelezo ya Nyumba',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Andika maelezo kamili kuhusu nyumba yako',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Maelezo ya Nyumba *',
                        hintText: '''
Mfano wa maelezo:
- Nyumba ina vyumba 3 vya kulala na vyumba 2 vya kuogea
- Samani kamili: vitanda, makabati, meza, viti
- Jikoni la kisasa na vifaa vyote
- Sehemu ya maegesho na bustani nzuri
- Usalama wa 24/7 na CCTV
- Karibu na shule, hospitali, na stendi ya mabasi
                        ''',
                        prefixIcon: Icon(Icons.description_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        helperText:
                            'Elezea kwa kina ili wateja waelewe vizuri (Angalau herufi 20)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Tafadhali weka maelezo ya nyumba";
                        }
                        if (value.length < 20) {
                          return "Maelezo yanapaswa kuwa na angalau herufi 20";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Herufi: ${_descriptionController.text.length}/500',
                        style: TextStyle(
                          fontSize: 12,
                          color: _descriptionController.text.length > 500
                              ? Colors.red
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💡 Vidokezo vya maelezo bora:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• Taja idadi ya vyumba, bafu, na maeneo ya kuegesha\n'
                                  '• Elezea samani na vifaa vilivyopo\n'
                                  '• Taja usalama na huduma zilizopo\n'
                                  '• Elezea ukaribu na shule, hospitali, na stendi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Maelezo ya Bei',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _rentPriceController,
                      decoration: InputDecoration(
                        labelText: 'Kodi ya Mwezi (TZS)',
                        prefixIcon: Icon(Icons.money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        helperText:
                            'Weka kodi ya kila mwezi kwa shilingi za Tanzania',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Tafadhali weka bei ya kukodisha";
                        }
                        if (double.tryParse(value) == null) {
                          return "Tafadhali weka namba sahihi";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _depositController,
                      decoration: InputDecoration(
                        labelText: 'Deposit / Kibali (TZS)',
                        prefixIcon: Icon(Icons.savings_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        helperText:
                            'Kiasi cha deposit (kawaida miezi 1-2) - Si lazima',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Yaliyojumuishwa kwenye kodi:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text('💧 Maji'),
                          selected: _waterIncluded,
                          onSelected: (val) =>
                              setState(() => _waterIncluded = val),
                          selectedColor: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF2E7D32),
                        ),
                        FilterChip(
                          label: Text('⚡ Umeme'),
                          selected: _electricityIncluded,
                          onSelected: (val) =>
                              setState(() => _electricityIncluded = val),
                          selectedColor: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF2E7D32),
                        ),
                        FilterChip(
                          label: Text('🌐 Internet'),
                          selected: _internetIncluded,
                          onSelected: (val) =>
                              setState(() => _internetIncluded = val),
                          selectedColor: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _nearbyAmenitiesController,
                      decoration: InputDecoration(
                        labelText:
                            'Vitu vilivyo karibu (Shule, Hospitali, Duka, Stendi)',
                        prefixIcon: Icon(Icons.place_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        helperText: 'Taja vitu muhimu vilivyo karibu na nyumba',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Taarifa za Eneo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Jaza taarifa kamili za eneo la nyumba',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 16),
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
                            debugPrint('📍 Full Address: $fullAddress');
                          },
                    ),
                    if (_selectedRegion.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2E7D32)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF2E7D32),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Anwani Kamili:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _locationDescriptionController.text,
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🗺️ Chagua Eneo kwenye Ramani',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
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
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Bonyeza kwenye ramani kuchagua eneo",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _getCurrentLocation,
                                    icon: Icon(Icons.my_location_rounded),
                                    label: Text("Tumia Eneo Langu la Sasa"),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
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
                                    markerId: gmap.MarkerId("nyumba"),
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
                    SizedBox(height: 12),
                    if (_locationAddress.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2E7D32)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: const Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Koordinati za Ramani:",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Text(
                                    _locationAddress,
                                    style: TextStyle(
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Muhimu: Hakikisha umejaza maelezo ya nyumba, taarifa zote za bei na eneo (Mkoa hadi Mtaa) na kuchagua eneo kwenye ramani.",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
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

  // ============================================================
  // NAVIGATION METHODS
  // ============================================================
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

  // ============================================================
  // VALIDATION METHODS
  // ============================================================
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        return true;
      case 2:
        if (_selectedImages.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali pakia angalau picha tatu")),
          );
          return false;
        }
        return true;
      case 3:
        if (_descriptionController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali weka maelezo ya nyumba")),
          );
          return false;
        }
        if (_descriptionController.text.length < 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Maelezo yanapaswa kuwa na angalau herufi 20"),
            ),
          );
          return false;
        }
        if (_rentPriceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali weka bei ya kukodisha")),
          );
          return false;
        }
        if (_selectedRegion.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali chagua Mkoa")),
          );
          return false;
        }
        if (_selectedDistrict.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali chagua Wilaya")),
          );
          return false;
        }
        if (_selectedWard.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali chagua Kata")),
          );
          return false;
        }
        if (_selectedStreet.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tafadhali weka jina la Mtaa")),
          );
          return false;
        }
        if (_selectedLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tafadhali chagua eneo la nyumba kwenye ramani"),
            ),
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  // ============================================================
  // IMAGE PICKING METHODS
  // ============================================================
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hitilafu ya kupakua picha: $e")));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ============================================================
  // LOCATION METHODS
  // ============================================================
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Huduma ya eneo haijawezeshwa")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ruhusa ya eneo imekataliwa")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ruhusa ya eneo imekataliwa kabisa")),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = gmap.LatLng(position.latitude, position.longitude);
      _selectLocation(location);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hitilafu ya kupata eneo: $e")));
    }
  }

  void _selectLocation(gmap.LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _locationAddress =
          "${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}";
    });
  }

  // lib/pages/house_registration_page.dart

  // ============================================================
  // SUBMIT FORM - USING API SERVICE WITH BASE64 IMAGES
  // ============================================================
  Future<void> _submitForm() async {
    if (_validateCurrentStep()) {
      setState(() {
        _isSubmitting = true;
        _uploadProgress = 0.0;
      });

      // Simulate upload progress UI
      for (int i = 0; i <= 90; i += 10) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() {
          _uploadProgress = i / 100;
        });
      }

      try {
        // ============================
        // 🔥 CONVERT IMAGES TO BASE64
        // ============================
        List<String> base64Images = [];
        for (var img in _selectedImages) {
          final bytes = await img.readAsBytes();
          final base64 = base64Encode(bytes);
          base64Images.add(base64);
        }

        // ============================
        // 📦 DATA YA KUPELEKA API
        // ============================
        final Map<String, dynamic> houseData = {
          "name": _houseNameController.text,
          "status": "Inapatikana",
          "type": _selectedHouseType,
          "bedrooms": _selectedBedrooms,
          "description": _descriptionController.text,
          "firstName": _brandNameController.text,
          "lastName": _houseNumberController.text,
          "phone": _phoneController.text,
          "rentPrice": double.parse(_rentPriceController.text),
          "location": _locationDescriptionController.text,
          "images": base64Images, // 🔥 Send Base64 instead of file names
          "latitude": _selectedLocation?.latitude,
          "longitude": _selectedLocation?.longitude,
          "address": _locationAddress,
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
        };

        // ============================
        // USE ApiService
        // ============================
        final savedHouse = await ApiService.addHouse(houseData);

        setState(() {
          _uploadProgress = 1.0;
        });

        if (savedHouse != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Nyumba imesajiliwa kikamilifu!"),
                backgroundColor: Colors.green,
              ),
            );

            widget.onHouseAdded(savedHouse);

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const RentalHomePage()),
              (route) => false,
            );
          }
        } else {
          throw Exception("Failed to save house - server returned null");
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hitilafu API: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
    super.dispose();
  }
}
