import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/services/notification_service.dart';

class LandlordVerificationPage extends StatefulWidget {
  const LandlordVerificationPage({super.key});

  @override
  State<LandlordVerificationPage> createState() => _LandlordVerificationPageState();
}

class _LandlordVerificationPageState extends State<LandlordVerificationPage>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  final PageController _pageController = PageController();

  // Multi-step flow state
  int _currentStep = 0;
  final int _totalSteps = 3; // Identity → Property → Submit
  
  // Identity verification data
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  File? _idPhoto;
  File? _selfie;
  File? _idDocument;

  // Property verification data
  File? _propertyDocument;
  List<File> _propertyPhotos = [];
  final TextEditingController _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Validation state
  bool _isSubmitting = false;

  // Animation
  late AnimationController _animationController;

  // NIDA number format validation
  final RegExp _nidaPattern = RegExp(r'^\d{8}-\d{5}-\d{5}-\d{2}$');

  bool _isValidNidaNumber(String value) {
    return _nidaPattern.hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _fullNameController.dispose();
    _ninController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickIdPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _idPhoto = File(image.path));
    }
  }

  Future<void> _pickSelfie() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selfie = File(image.path));
    }
  }

  Future<void> _pickIdDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _idDocument = File(result.files.single.path!));
    }
  }

  Future<void> _pickPropertyDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _propertyDocument = File(result.files.single.path!));
    }
  }

  Future<void> _pickPropertyPhotos() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() {
        _propertyPhotos = images.map((image) => File(image.path)).toList();
      });
    }
  }

  bool _validateIdentityStep() {
    if (_fullNameController.text.isEmpty ||
        _ninController.text.isEmpty ||
        _idPhoto == null ||
        _selfie == null) {
      _showErrorSnackBar(context.tr('Tafadhali jaza sehemu zote', en: 'Please fill all fields'));
      return false;
    }

    if (!_isValidNidaNumber(_ninController.text)) {
      _showErrorSnackBar(context.tr(
        'NIDA number format si sahihi. Use format: 19950923-54203-00012-28',
        en: 'Invalid NIDA format. Use: 19950923-54203-00012-28',
      ));
      return false;
    }

    return true;
  }

  bool _validatePropertyStep() {
    if (_propertyDocument == null || _propertyPhotos.isEmpty) {
      _showErrorSnackBar(context.tr(
        'Tafadhali pakia documents na picha za nyumba',
        en: 'Please upload property documents and photos',
      ));
      return false;
    }

    if (_addressController.text.isEmpty) {
      _showErrorSnackBar(context.tr('Tafadhali jawa anwani ya nyumba', en: 'Please enter property address'));
      return false;
    }

    return true;
  }

  Future<void> _submitCompleteVerification() async {
    setState(() => _isSubmitting = true);

    try {
      // Submit complete verification as a single application
      final success = await ApiService.submitCompleteVerification(
        fullName: _fullNameController.text.trim(),
        ninNumber: _ninController.text.trim(),
        idPhoto: _idPhoto!,
        selfie: _selfie!,
        idDocument: _idDocument,
        propertyDocument: _propertyDocument!,
        propertyPhotos: _propertyPhotos,
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar(context.tr('Verification submitted successfully', en: 'Verification submitted successfully'));
        setState(() => _currentStep = 3); // Complete
        NotificationService.instance.cancelVerificationReminder();
        _showCompletionDialog();
      } else {
        _showErrorSnackBar(context.tr('Imeshindwa kuwasilisha', en: 'Submission failed'));
      }
    } catch (e) {
      debugPrint('Error submitting complete verification: $e');
      if (mounted) {
        _showErrorSnackBar('${context.tr('Hitilafu', en: 'Error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              context.tr('Verification Submitted', en: 'Verification Submitted'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          context.tr(
            'Your verification has been submitted successfully. The admin will review your application.',
            en: 'Your verification has been submitted successfully. The admin will review your application.',
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text(context.tr('OK', en: 'OK')),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Identity step validation
      if (_validateIdentityStep()) {
        setState(() => _currentStep = 1);
        _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep == 1) {
      // Property step validation
      if (_validatePropertyStep()) {
        setState(() => _currentStep = 2);
        _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final primaryColor = const Color(0xFF0F8B61);
    final backgroundColor = isDarkMode ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8);
    final cardColor = isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE6EDF3) : const Color(0xFF0D1117);
    final subtextColor = isDarkMode ? const Color(0xFF8B949E) : const Color(0xFF656D76);
    final borderColor = isDarkMode ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('Landlord Verification', en: 'Landlord Verification'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(isDarkMode, primaryColor, textColor, subtextColor, borderColor),
          
          // Page view for steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildIdentityStep(isDarkMode, cardColor, textColor, subtextColor, borderColor, primaryColor),
                _buildPropertyStep(isDarkMode, cardColor, textColor, subtextColor, borderColor, primaryColor),
                _buildSubmitStep(isDarkMode, cardColor, textColor, subtextColor, borderColor, primaryColor),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(isDarkMode, primaryColor, textColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    // Step circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent 
                            ? primaryColor 
                            : isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted || isCurrent 
                              ? primaryColor 
                              : borderColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color: isCurrent ? Colors.white : subtextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    
                    // Progress line
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCompleted ? primaryColor : borderColor,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStepLabel('Identity', 0, isDarkMode, textColor, subtextColor),
              _buildStepLabel('Property', 1, isDarkMode, textColor, subtextColor),
              _buildStepLabel('Submit', 2, isDarkMode, textColor, subtextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label, int step, bool isDarkMode, Color textColor, Color subtextColor) {
    final isCurrent = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: isCurrent || isCompleted ? FontWeight.w600 : FontWeight.w400,
        color: isCurrent || isCompleted ? textColor : subtextColor,
      ),
    );
  }

  Widget _buildIdentityStep(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identity Verification',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your identity information for verification',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Full Name
          _buildTextField(
            _fullNameController,
            'Full Name',
            Icons.person,
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          
          // NIN Number
          TextField(
            controller: _ninController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _NidaFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'NIN Number',
              labelStyle: GoogleFonts.poppins(color: subtextColor),
              hintText: '19950923-54203-00012-28',
              hintStyle: GoogleFonts.poppins(color: subtextColor),
              prefixIcon: const Icon(Icons.badge),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
            style: GoogleFonts.poppins(color: textColor),
          ),
          const SizedBox(height: 24),
          
          // Photo uploads
          Text(
            'Upload Documents',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPhotoUploadCard(
                  'ID Photo',
                  _idPhoto,
                  _pickIdPhoto,
                  Icons.credit_card,
                  isDarkMode,
                  cardColor,
                  textColor,
                  subtextColor,
                  borderColor,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPhotoUploadCard(
                  'Selfie',
                  _selfie,
                  _pickSelfie,
                  Icons.face,
                  isDarkMode,
                  cardColor,
                  textColor,
                  subtextColor,
                  borderColor,
                  primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildDocumentUploadCard(
            'ID Document (PDF/DOC)',
            _idDocument,
            _pickIdDocument,
            Icons.description,
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStep(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Verification',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide property ownership documentation',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Address
          _buildTextField(
            _addressController,
            'Property Address',
            Icons.location_on,
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
          ),
          const SizedBox(height: 24),
          
          // Property document
          Text(
            'Property Documents',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDocumentUploadCard(
            'Property Ownership Document',
            _propertyDocument,
            _pickPropertyDocument,
            Icons.home_work,
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
            primaryColor,
          ),
          const SizedBox(height: 16),
          
          // Property photos
          Text(
            'Property Photos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildPhotoUploadCard(
            'Add Property Photos',
            null,
            _pickPropertyPhotos,
            Icons.add_photo_alternate,
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
            primaryColor,
            isMultiple: true,
          ),
          
          if (_propertyPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _propertyPhotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _propertyPhotos[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _propertyPhotos.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitStep(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF0F8B61),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Ready to Submit',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your information before submitting',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Summary cards
          _buildSummaryCard(
            'Identity Information',
            [
              'Name: ${_fullNameController.text}',
              'NIN: ${_ninController.text}',
              'ID Photo: ${_idPhoto != null ? 'Uploaded' : 'Not uploaded'}',
              'Selfie: ${_selfie != null ? 'Uploaded' : 'Not uploaded'}',
            ],
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          
          _buildSummaryCard(
            'Property Information',
            [
              'Address: ${_addressController.text}',
              'Document: ${_propertyDocument != null ? 'Uploaded' : 'Not uploaded'}',
              'Photos: ${_propertyPhotos.length} uploaded',
            ],
            isDarkMode,
            cardColor,
            textColor,
            subtextColor,
            borderColor,
          ),
          
          const SizedBox(height: 32),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitCompleteVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Submit Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDarkMode, Color primaryColor, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _currentStep == 2 ? _submitCompleteVerification : _nextStep,
              icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
              label: Text(_currentStep == 2 ? 'Submit' : 'Next'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: subtextColor),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F8B61)),
        ),
      ),
      style: GoogleFonts.poppins(color: textColor),
    );
  }

  Widget _buildPhotoUploadCard(
    String label,
    File? file,
    VoidCallback onTap,
    IconData icon,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor, {
    bool isMultiple = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: file != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isMultiple) {
                            _propertyPhotos.clear();
                          } else if (label == 'ID Photo') {
                            _idPhoto = null;
                          } else if (label == 'Selfie') {
                            _selfie = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: subtextColor, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDocumentUploadCard(
    String label,
    File? file,
    VoidCallback onTap,
    IconData icon,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    Color primaryColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file != null ? file.path.split('/').last : label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    file != null ? 'Uploaded' : 'Tap to upload',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (file != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    if (label.contains('Property')) {
                      _propertyDocument = null;
                    } else {
                      _idDocument = null;
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    List<String> items,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF0F8B61), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: subtextColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _NidaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 20) {
      return oldValue;
    }
    
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 8 || i == 13 || i == 18) {
        formatted += '-';
      }
      formatted += digits[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
