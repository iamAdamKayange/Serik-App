import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';

class LandlordVerificationPage extends StatefulWidget {
  const LandlordVerificationPage({super.key});

  @override
  State<LandlordVerificationPage> createState() =>
      _LandlordVerificationPageState();
}

class _LandlordVerificationPageState extends State<LandlordVerificationPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();

  // Identity verification
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  File? _idPhoto;
  File? _selfie;
  File? _idDocument; // PDF/DOC support

  // Property verification
  File? _propertyDocument;
  List<File> _propertyPhotos = [];
  final TextEditingController _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Progress tracking
  String _currentStep = 'identity'; // identity, property, complete
  Map<String, dynamic>? _verificationStatus;
  bool _isLoading = false;
  bool _isSubmitting = false;
  // ignore: unused_field
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadVerificationStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _ninController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await ApiService.getVerificationStatus();
      setState(() {
        _verificationStatus = status;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading verification status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _submitIdentityVerification() async {
    if (_fullNameController.text.isEmpty ||
        _ninController.text.isEmpty ||
        _idPhoto == null ||
        _selfie == null) {
      _showErrorSnackBar(context.tr(
        'Tafadhali jaza sehemu zote',
        en: 'Please fill all fields',
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitIdentityVerification(
        fullName: _fullNameController.text,
        ninNumber: _ninController.text,
        idPhoto: _idPhoto!,
        selfie: _selfie!,
        idDocument: _idDocument,
      );
      _showSuccessSnackBar(context.tr(
        'Uthibitishaji wa utambulisho umetumwa',
        en: 'Identity verification submitted',
      ));
      setState(() => _currentStep = 'property');
      await _loadVerificationStatus();
    } catch (e) {
      _showErrorSnackBar(context.tr(
        'Hitilafu: $e',
        en: 'Error: $e',
      ));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitPropertyVerification() async {
    if (_propertyDocument == null || _propertyPhotos.isEmpty) {
      _showErrorSnackBar(context.tr(
        'Tafadhali weka document na picha za mali',
        en: 'Please upload property document and photos',
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitPropertyVerification(
        propertyDocument: _propertyDocument!,
        propertyPhotos: _propertyPhotos,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text,
      );
      _showSuccessSnackBar(context.tr(
        'Uthibitishaji wa mali umetumwa',
        en: 'Property verification submitted',
      ));
      setState(() => _currentStep = 'complete');
      await _loadVerificationStatus();
    } catch (e) {
      _showErrorSnackBar(context.tr(
        'Hitilafu: $e',
        en: 'Error: $e',
      ));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFB45309),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final locale = Localizations.localeOf(context);
    final isSwahili = locale.languageCode == 'sw';

    final primaryColor = isDark
        ? const Color(0xFF46D39A)
        : const Color(0xFF0F8B61);
    final backgroundColor = isDark
        ? const Color(0xFF0D1110)
        : const Color(0xFFF7F9F8);
    final cardColor = isDark ? const Color(0xFF171C1A) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFF2F7F4)
        : const Color(0xFF15201C);
    final subtextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isSwahili ? 'Uthibitishaji wa Mpangishaji' : 'Landlord Verification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF46D39A),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSwahili ? 'Inasubiri...' : 'Loading...',
                    style: GoogleFonts.poppins(
                      color: subtextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    _buildProgressIndicator(
                      isDark,
                      primaryColor,
                      cardColor,
                      textColor,
                      subtextColor,
                      isSwahili,
                    ),
                    const SizedBox(height: 24),

                    // Verification Status Card
                    if (_verificationStatus != null)
                      _buildVerificationStatusCard(
                        _verificationStatus!,
                        isDark,
                        cardColor,
                        primaryColor,
                        textColor,
                        subtextColor,
                        isSwahili,
                      ),
                    if (_verificationStatus != null) const SizedBox(height: 24),

                    // Content based on current step
                    if (_currentStep == 'identity')
                      _buildIdentityVerificationSection(
                        isDark,
                        cardColor,
                        primaryColor,
                        textColor,
                        subtextColor,
                        shadowColor,
                        isSwahili,
                      )
                    else if (_currentStep == 'property')
                      _buildPropertyVerificationSection(
                        isDark,
                        cardColor,
                        primaryColor,
                        textColor,
                        subtextColor,
                        shadowColor,
                        isSwahili,
                      )
                    else
                      _buildCompleteSection(
                        isDark,
                        cardColor,
                        primaryColor,
                        textColor,
                        subtextColor,
                        shadowColor,
                        isSwahili,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressIndicator(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final steps = [
      {'label': isSwahili ? 'Utambulisho' : 'Identity', 'icon': Icons.person},
      {'label': isSwahili ? 'Mali' : 'Property', 'icon': Icons.home},
      {
        'label': isSwahili ? 'Kamilika' : 'Complete',
        'icon': Icons.check_circle,
      },
    ];

    int currentStepIndex = _currentStep == 'identity'
        ? 0
        : _currentStep == 'property'
        ? 1
        : 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isCompleted = index < currentStepIndex;
          final isCurrent = index == currentStepIndex;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? primaryColor
                                : subtextColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? primaryColor
                            : subtextColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCompleted || isCurrent
                              ? primaryColor
                              : subtextColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step['icon'] as IconData,
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : subtextColor,
                        size: 20,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? primaryColor
                                : subtextColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step['label'] as String,
                  style: GoogleFonts.poppins(
                    color: isCompleted || isCurrent
                        ? primaryColor
                        : subtextColor,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerificationStatusCard(
    Map<String, dynamic> status,
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    bool isSwahili,
  ) {
    final identityStatus = status['identityStatus'] as String?;
    final propertyStatus = status['propertyStatus'] as String?;
    final canPublish = status['canPublish'] as bool? ?? false;
    
    // New fields for retry logic
    final canResubmit = status['canResubmit'] as bool? ?? false;
    final retryAfter = status['retryAfter'] as int? ?? 0;
    final retryReason = status['retryReason'] as String? ?? '';
    final daysSinceSubmission = status['daysSinceSubmission'] as int? ?? 0;

    String statusText = canPublish
        ? (isSwahili ? 'Umethibitishwa ✓' : 'Verified ✓')
        : (isSwahili ? 'Inasubiri Uthibitishaji' : 'Pending Verification');

    Color statusColor = canPublish
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canPublish
              ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
              : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  canPublish ? Icons.verified_rounded : Icons.pending_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusRow(
                  isSwahili ? 'Uthibitishaji wa Utambulisho' : 'Identity',
                  identityStatus,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildStatusRow(
                  isSwahili ? 'Uthibitishaji wa Mali' : 'Property',
                  propertyStatus,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Show retry information if verification was rejected
          if (!canPublish && (identityStatus == 'rejected' || propertyStatus == 'rejected')) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        canResubmit ? Icons.info_outline : Icons.block,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          canResubmit
                              ? (isSwahili ? 'Unaweza kujaribu tena' : 'You can resubmit')
                              : (isSwahili ? 'Subiri maombi yako' : 'Please wait before resubmitting'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!canResubmit && retryAfter > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      isSwahili
                          ? 'Subiri $retryAfter siku'
                          : 'Wait $retryAfter days',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if (retryReason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      isSwahili
                          ? 'Sababu: $retryReason'
                          : 'Reason: $retryReason',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  canPublish ? Icons.check_circle : Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canPublish
                        ? (isSwahili
                              ? 'Unaweza kuweka nyumba zako sasa'
                              : 'You can now list your properties')
                        : (isSwahili
                              ? 'Kamilisha hatua zote ili kuthibitishwa'
                              : 'Complete all steps to get verified'),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String? status, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'verified':
        statusColor = Colors.white;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red.shade300;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.amber.shade300;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.white.withValues(alpha: 0.6);
        statusIcon = Icons.help_outline;
    }

    final locale = Localizations.localeOf(context);
    final isSwahili = locale.languageCode == 'sw';

    String statusLabel =
        status?.toUpperCase() ?? (isSwahili ? 'HAIJATUMWA' : 'NOT SUBMITTED');
    if (isSwahili) {
      if (status == 'verified') {
        statusLabel = 'IMETHIBITISHWA';
      } else if (status == 'rejected') {
        statusLabel = 'IMEKATALIWA';
      } else if (status == 'pending') {
        statusLabel = 'INASUBIRI';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              statusLabel,
              style: GoogleFonts.poppins(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityVerificationSection(
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color shadowColor,
    bool isSwahili,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isSwahili
                    ? 'Uthibitishaji wa Utambulisho'
                    : 'Identity Verification',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fullNameController,
            style: GoogleFonts.poppins(color: textColor),
            decoration: InputDecoration(
              labelText: isSwahili ? 'Jina Kamili' : 'Full Name',
              labelStyle: GoogleFonts.poppins(color: subtextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF26312D)
                      : const Color(0xFFE2E8E5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF26312D)
                      : const Color(0xFFE2E8E5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.person, color: subtextColor),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF111614)
                  : const Color(0xFFF1F5F3),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ninController,
            style: GoogleFonts.poppins(color: textColor),
            decoration: InputDecoration(
              labelText: isSwahili
                  ? 'Nambari ya NIN/Kitambulisho'
                  : 'NIN/ID Number',
              labelStyle: GoogleFonts.poppins(color: subtextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF26312D)
                      : const Color(0xFFE2E8E5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF26312D)
                      : const Color(0xFFE2E8E5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.numbers, color: subtextColor),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF111614)
                  : const Color(0xFFF1F5F3),
            ),
          ),
          const SizedBox(height: 12),
          _buildImagePicker(
            context.tr('Picha ya Kitambulisho', en: 'ID Photo'),
            _idPhoto,
            _pickIdPhoto,
            isDark,
            primaryColor,
            subtextColor,
          ),
          const SizedBox(height: 12),
          _buildImagePicker(
            context.tr('Selfie', en: 'Selfie'),
            _selfie,
            _pickSelfie,
            isDark,
            primaryColor,
            subtextColor,
          ),
          const SizedBox(height: 12),
          _buildDocumentPicker(
            context.tr(
                'Hati ya Utambulisho (PDF/DOC)',
                en: 'ID Document (PDF/DOC)'),
            _idDocument,
            _pickIdDocument,
            isDark,
            primaryColor,
            subtextColor,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitIdentityVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: subtextColor,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      context.tr(
                          'Tuma Uthibitishaji wa Utambulisho',
                          en: 'Submit Identity Verification'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyVerificationSection(
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color shadowColor,
    bool isSwahili,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isSwahili ? 'Uthibitishaji wa Mali' : 'Property Verification',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentPicker(
            context.tr(
                'Hati ya Mali (PDF/DOC)',
                en: 'Property Document (PDF/DOC)'),
            _propertyDocument,
            _pickPropertyDocument,
            isDark,
            primaryColor,
            subtextColor,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickPropertyPhotos,
              icon: Icon(Icons.photo_library_rounded, color: primaryColor),
              label: Text(
                context.tr(
                    'Ongeza Picha za Mali (${_propertyPhotos.length})',
                    en: 'Add Property Photos (${_propertyPhotos.length})'),
                style: GoogleFonts.poppins(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: primaryColor),
              ),
            ),
          ),
          if (_propertyPhotos.isNotEmpty) const SizedBox(height: 8),
          if (_propertyPhotos.isNotEmpty)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _propertyPhotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_propertyPhotos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            style: GoogleFonts.poppins(color: textColor),
            decoration: InputDecoration(
              labelText: isSwahili ? 'Anwani ya Mali' : 'Property Address',
              labelStyle: GoogleFonts.poppins(color: subtextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF26312D)
                      : const Color(0xFFE2E8E5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF26312D)
                      : const Color(0xFFE2E8E5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              prefixIcon: Icon(Icons.location_on, color: subtextColor),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF111614)
                  : const Color(0xFFF1F5F3),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPropertyVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: subtextColor,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      context.tr(
                          'Tuma Uthibitishaji wa Mali',
                          en: 'Submit Property Verification'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteSection(
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
    Color shadowColor,
    bool isSwahili,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF26312D), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: primaryColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Imekamilika!' : 'Completed!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Uthibitishaji wako umekamilika. Admin atathibitisha ombi lako hivi karibuni.'
                : 'Your verification is complete. An admin will review your request shortly.',
            style: GoogleFonts.poppins(color: subtextColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              isSwahili ? 'Rudi Nyumbani' : 'Go Back',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(
    String label,
    File? imageFile,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111614) : const Color(0xFFF1F5F3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF26312D) : const Color(0xFFE2E8E5),
            style: BorderStyle.solid,
          ),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF4CAF50),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Selected',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: subtextColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Tap to upload',
                      style: GoogleFonts.poppins(
                        color: subtextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDocumentPicker(
    String label,
    File? documentFile,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
    Color subtextColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111614) : const Color(0xFFF1F5F3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF26312D) : const Color(0xFFE2E8E5),
            style: BorderStyle.solid,
          ),
        ),
        child: documentFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: primaryColor.withValues(alpha: 0.1),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: primaryColor,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              documentFile.path.split('/').last,
                              style: GoogleFonts.poppins(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF4CAF50),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Selected',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 36,
                      color: subtextColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Tap to upload (PDF, DOC, JPG)',
                      style: GoogleFonts.poppins(
                        color: subtextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
