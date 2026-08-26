import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';

class LandlordVerificationPage extends StatefulWidget {
  const LandlordVerificationPage({super.key});

  @override
  State<LandlordVerificationPage> createState() => _LandlordVerificationPageState();
}

class _LandlordVerificationPageState extends State<LandlordVerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();
  
  // Identity verification
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  File? _idPhoto;
  File? _selfie;
  
  // Property verification
  File? _propertyDocument;
  List<File> _propertyPhotos = [];
  final TextEditingController _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, dynamic>? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await ApiService.getVerificationStatus();
      setState(() {
        _verificationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load verification status';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickIdPhoto() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _idPhoto = File(image.path));
    }
  }

  Future<void> _pickSelfie() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selfie = File(image.path));
    }
  }

  Future<void> _pickPropertyDocument() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _propertyDocument = File(image.path));
    }
  }

  Future<void> _pickPropertyPhotos() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali jaza sehemu zote')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.submitIdentityVerification(
        fullName: _fullNameController.text,
        ninNumber: _ninController.text,
        idPhoto: _idPhoto!,
        selfie: _selfie!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification imetumwa kikamilifu')),
      );
      await _loadVerificationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPropertyVerification() async {
    if (_propertyDocument == null || _propertyPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka document na picha za mali')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.submitPropertyVerification(
        propertyDocument: _propertyDocument!,
        propertyPhotos: _propertyPhotos,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification imetumwa kikamilifu')),
      );
      await _loadVerificationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Landlord Verification'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_verificationStatus != null) _buildVerificationStatusCard(_verificationStatus!, isDark, cardColor, primaryColor),
                  const SizedBox(height: 24),
                  _buildIdentityVerificationSection(isDark, cardColor, primaryColor),
                  const SizedBox(height: 24),
                  _buildPropertyVerificationSection(isDark, cardColor, primaryColor),
                ],
              ),
            ),
    );
  }

  Widget _buildVerificationStatusCard(Map<String, dynamic> status, bool isDark, Color cardColor, Color primaryColor) {
    final identityStatus = status['identityStatus'] as String?;
    final propertyStatus = status['propertyStatus'] as String?;
    final canPublish = status['canPublish'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: canPublish ? primaryColor : Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canPublish ? Icons.verified : Icons.pending,
                color: canPublish ? primaryColor : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                canPublish ? 'Verified - Unaweza kuweka nyumba' : 'Pending Verification',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: canPublish ? primaryColor : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow('Identity Verification', identityStatus, isDark),
          _buildStatusRow('Property Verification', propertyStatus, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String? status, bool isDark) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 4),
            Text(
              status?.toUpperCase() ?? 'NOT SUBMITTED',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentityVerificationSection(bool isDark, Color cardColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identity Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ninController,
            decoration: InputDecoration(
              labelText: 'NIN/ID Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildImagePicker('ID Photo', _idPhoto, _pickIdPhoto),
          const SizedBox(height: 12),
          _buildImagePicker('Selfie', _selfie, _pickSelfie),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitIdentityVerification,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Submit Identity Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyVerificationSection(bool isDark, Color cardColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildImagePicker('Property Document', _propertyDocument, _pickPropertyDocument),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickPropertyPhotos,
            icon: const Icon(Icons.photo_library),
            label: Text('Add Property Photos (${_propertyPhotos.length})'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Property Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitPropertyVerification,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Submit Property Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(String label, File? imageFile, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate, size: 32),
                    const SizedBox(height: 8),
                    Text(label),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ninController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
