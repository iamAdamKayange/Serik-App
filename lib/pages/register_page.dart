// lib/pages/register_page.dart
// 🔥 USING first_name and last_name WITH THEME PROVIDER

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/pages/login_page.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/providers/theme_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String _selectedRole = 'normal';

  // Helper getters for theme colors
  bool get isDarkMode =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  Color get primaryColor =>
      isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
  Color get surfaceColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color? get hintTextColor => isDarkMode ? Colors.grey[400] : Colors.grey[600];
  Color get borderColor => isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
  Color get roleBgColor => isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
  Color get inputFillColor => isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;

  List<Color> get gradientColors => isDarkMode
      ? [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)]
      : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)];

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenosiri hazilingani!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lazima ukubali sheria na masharti'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('📡 Registering with ApiService...');
      debugPrint('📧 Email: ${_emailController.text.trim()}');
      debugPrint('👤 First Name: ${_firstNameController.text.trim()}');
      debugPrint('👤 Last Name: ${_lastNameController.text.trim()}');
      debugPrint('🎭 Role: $_selectedRole');

      final result = await ApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );

      debugPrint('📦 Register response: $result');

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Usajili umefanikiwa! Tafadhali ingia.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Usajili umeshindikana. Jaribu tena.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Back Button Only (No Dark Mode Toggle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Animation
                  Center(
                    child: SizedBox(
                      height: 150,
                      child: Lottie.asset(
                        "assets/animations/register.json",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome Text
                  Text(
                    'Undaa Akaunti Mpya',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jisajili kuanza kutafuta nyumba',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Registration Form Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Role Selection
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: roleBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildRoleChip('Mtumiaji', 'normal'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRoleChip(
                                    'Mwenye Nyumba',
                                    'landlord',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // First Name
                          _buildField(
                            'Jina la Kwanza',
                            _firstNameController,
                            Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Jina la kwanza linahitajika'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          _buildField(
                            'Jina la Mwisho',
                            _lastNameController,
                            Icons.person_outline,
                            validator: (v) => null,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildField(
                            'Barua Pepe',
                            _emailController,
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Barua pepe inahitajika'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Phone (Optional)
                          _buildField(
                            'Namba ya Simu (Si lazima)',
                            _phoneController,
                            Icons.phone_android,
                            keyboardType: TextInputType.phone,
                            validator: (v) => null,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildPasswordField(),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildConfirmPasswordField(),
                          const SizedBox(height: 16),

                          // Terms
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                onChanged: (value) => setState(
                                  () => _agreeToTerms = value ?? false,
                                ),
                                activeColor: primaryColor,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[400]!,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Nakubali sheria na masharti',
                                  style: TextStyle(
                                    color: hintTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (_agreeToTerms && !_isLoading)
                                  ? _registerUser
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'JISAJILI',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tayari una akaunti?',
                                style: TextStyle(color: hintTextColor),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                ),
                                child: Text(
                                  'Ingia Hapa',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, String value) {
    final bool isSelected = _selectedRole == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintTextColor),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(
        labelText: 'Nenosiri',
        labelStyle: TextStyle(color: hintTextColor),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.lock_outline, color: primaryColor),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: isDarkMode ? Colors.grey[400] : Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Tafadhali weka nenosiri';
        if (value.length < 6) return 'Nenosiri lazima iwe angalau herufi 6';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(
        labelText: 'Thibitisha Nenosiri',
        labelStyle: TextStyle(color: hintTextColor),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.lock_outline, color: primaryColor),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: isDarkMode ? Colors.grey[400] : Colors.grey,
          ),
          onPressed: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tafadhali thibitisha nenosiri';
        }
        if (value != _passwordController.text) return 'Nenosiri hazilingani';
        return null;
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
