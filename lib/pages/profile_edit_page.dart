import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/widgets/custom_dialogs.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profile;
  XFile? _avatarFile;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ApiService.getMe();
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _firstNameController.text = profile?['first_name']?.toString() ?? '';
      _lastNameController.text = profile?['last_name']?.toString() ?? '';
      _phoneController.text = profile?['phone']?.toString() ?? '';
      _avatarUrl = profile?['profile_image_url']?.toString() ??
          profile?['profileImageUrl']?.toString();
      _isLoading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (!mounted || picked == null) return;
    setState(() => _avatarFile = picked);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final result = await ApiService.updateMe(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarFile: _avatarFile,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result == null) {
      CustomDialogs.showError(
        context,
        context.tr(
          'Imeshindwa kuhifadhi profaili. Jaribu tena.',
          en: 'Could not save profile. Please try again.',
        ),
      );
      return;
    }

    final user = result['user'] as Map<String, dynamic>? ?? result;
    final auth = context.read<AuthProvider>();
    final fullName = [
      user['first_name']?.toString() ?? _firstNameController.text.trim(),
      user['last_name']?.toString() ?? _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    auth.updateProfile(
      userName: fullName,
      phone: user['phone']?.toString() ?? _phoneController.text.trim(),
      avatarUrl: user['profile_image_url']?.toString() ??
          user['profileImageUrl']?.toString() ??
          _avatarUrl,
    );

    CustomDialogs.showSuccess(
      context,
      context.tr(
        'Profaili imehifadhiwa kikamilifu.',
        en: 'Profile updated successfully.',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final l10n = AppLocalizations.of(context);
    final primary = isDark ? const Color(0xFF46D39A) : const Color(0xFF0F8B61);
    final bg = isDark ? const Color(0xFF0D1110) : const Color(0xFFF7F9F8);
    final card = isDark ? const Color(0xFF171C1A) : Colors.white;
    final text = isDark ? const Color(0xFFF2F7F4) : const Color(0xFF15201C);
    final sub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          l10n.tr('Hariri Profaili', en: 'Edit Profile'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('Sasisha taarifa zako', en: 'Update your details'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.tr(
                          'Mabadiliko yanaonekana mara moja kwenye app baada ya kuhifadhi.',
                          en: 'Changes are reflected immediately after saving.',
                        ),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: primary.withValues(alpha: 0.12),
                            foregroundImage: _avatarFile != null
                                ? FileImage(File(_avatarFile!.path))
                                : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                            child: _avatarFile == null &&
                                    (_avatarUrl == null || _avatarUrl!.isEmpty)
                                ? Text(
                                    [
                                      _firstNameController.text.trim(),
                                      _lastNameController.text.trim(),
                                    ]
                                        .where((part) => part.isNotEmpty)
                                        .map((part) => part[0])
                                        .take(2)
                                        .join()
                                        .toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: InkWell(
                              onTap: _isSaving ? null : _pickAvatar,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: card, width: 3),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.tr('Picha ya Profaili', en: 'Profile Photo'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.tr(
                          'Gusa duara kubadilisha picha yako.',
                          en: 'Tap the avatar to change your photo.',
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: sub,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: l10n.tr('Jina la Kwanza', en: 'First Name'),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? l10n.tr('Tafadhali jaza jina la kwanza', en: 'Enter first name')
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: l10n.tr('Jina la Mwisho', en: 'Last Name'),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? l10n.tr('Tafadhali jaza jina la mwisho', en: 'Enter last name')
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.tr('Namba ya Simu', en: 'Phone Number'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving ? null : () => Navigator.pop(context),
                                child: Text(l10n.tr('Funga', en: 'Close')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        l10n.tr('Hifadhi', en: 'Save'),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_profile != null)
                  Text(
                    '${l10n.tr('Barua pepe', en: 'Email')}: ${_profile!['email'] ?? ''}',
                    style: GoogleFonts.poppins(color: sub, fontSize: 12),
                  ),
              ],
            ),
    );
  }
}
