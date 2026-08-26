import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';

class AdminVerificationReviewPage extends StatefulWidget {
  const AdminVerificationReviewPage({super.key});

  @override
  State<AdminVerificationReviewPage> createState() => _AdminVerificationReviewPageState();
}

class _AdminVerificationReviewPageState extends State<AdminVerificationReviewPage> {
  int _selectedTab = 0; // 0: Identity, 1: Property
  bool _isLoading = false;
  List<dynamic> _pendingVerifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() => _isLoading = true);
    try {
      final verifications = _selectedTab == 0
          ? await ApiService.getPendingIdentityVerifications()
          : await ApiService.getPendingPropertyVerifications();
      setState(() {
        _pendingVerifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pending verifications';
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewVerification(String verificationId, String status, {String? adminNotes}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $status'),
        content: Text('Are you sure you want to $status this verification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final success = _selectedTab == 0
            ? await ApiService.reviewIdentityVerification(
                verificationId: verificationId,
                status: status,
                adminNotes: adminNotes,
              )
            : await ApiService.reviewPropertyVerification(
                verificationId: verificationId,
                status: status,
                adminNotes: adminNotes,
              );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification $status successfully')),
          );
          await _loadPendingVerifications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to review verification')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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
        title: const Text('Admin Verification Review'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTabBar(isDark, primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _pendingVerifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No pending verifications',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pendingVerifications.length,
                            itemBuilder: (context, index) {
                              final verification = _pendingVerifications[index];
                              return _buildVerificationCard(
                                verification,
                                isDark,
                                cardColor,
                                primaryColor,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _loadPendingVerifications();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Identity Verification',
                    style: TextStyle(
                      color: _selectedTab == 0 ? primaryColor : Colors.grey,
                      fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                  _loadPendingVerifications();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1 ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Property Verification',
                    style: TextStyle(
                      color: _selectedTab == 1 ? primaryColor : Colors.grey,
                      fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> verification, bool isDark, Color cardColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID: ${verification['user_id']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email: ${verification['email']}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (verification['phone'] != null)
                      Text(
                        'Phone: ${verification['phone']}',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Text(
                'Pending',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedTab == 0) _buildIdentityDetails(verification, isDark),
          if (_selectedTab == 1) _buildPropertyDetails(verification, isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewVerification(
                    verification['id'].toString(),
                    'verified',
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewVerification(
                    verification['id'].toString(),
                    'rejected',
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityDetails(Map<String, dynamic> verification, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Full Name', verification['full_name'], isDark),
        _buildDetailRow('NIN Number', verification['nin_number'], isDark),
        if (verification['id_photo_url'] != null)
          _buildDetailRow('ID Photo', verification['id_photo_url'], isDark),
        if (verification['selfie_photo_url'] != null)
          _buildDetailRow('Selfie', verification['selfie_photo_url'], isDark),
        _buildDetailRow('Submitted', verification['submitted_at'], isDark),
      ],
    );
  }

  Widget _buildPropertyDetails(Map<String, dynamic> verification, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (verification['property_document_url'] != null)
          _buildDetailRow('Document', verification['property_document_url'], isDark),
        if (verification['property_photos'] != null && verification['property_photos'].isNotEmpty)
          _buildDetailRow('Photos', '${verification['property_photos'].length} photos', isDark),
        if (verification['latitude'] != null && verification['longitude'] != null)
          _buildDetailRow('Location', '${verification['latitude']}, ${verification['longitude']}', isDark),
        if (verification['address'] != null)
          _buildDetailRow('Address', verification['address'], isDark),
        _buildDetailRow('Submitted', verification['submitted_at'], isDark),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
