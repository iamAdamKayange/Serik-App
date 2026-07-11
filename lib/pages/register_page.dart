import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/l10n/app_localization.dart';
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
        SnackBar(
          content: Text(
            context.tr('Nenosiri hazilingani!', en: 'Passwords do not match!'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Lazima ukubali sheria na masharti',
              en: 'You must accept the terms and conditions',
            ),
          ),
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
        // 🔥 Show success dialog with Lottie tick.json instead of SnackBar
        await _showSuccessDialog();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Usajili umeshindikana. Jaribu tena.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('Hitilafu', en: 'Error')}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 New: Show success dialog with tick.json animation
  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              "assets/animations/tick.json",
              height: 120,
              width: 120,
              repeat: false,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Usajili Umefanikiwa!', en: 'Registration Successful!'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'Tafadhali ingia kwenye akaunti yako.',
                en: 'Please sign in to your account.',
              ),
              style: TextStyle(fontSize: 14, color: hintTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('Endelea Kuingia', en: 'Continue to Login'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
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
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
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
                    context.tr(
                      'Undaa Akaunti Mpya',
                      en: 'Create a New Account',
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Jisajili kuanza kutafuta nyumba',
                      en: 'Register to start finding houses',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
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
                          color: Colors.black.withValues(alpha: 0.1),
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
                                  child: _buildRoleChip(
                                    context.tr('Mtumiaji', en: 'User'),
                                    'normal',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRoleChip(
                                    context.tr(
                                      'Mwenye Nyumba',
                                      en: 'Landlord',
                                    ),
                                    'landlord',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // First Name
                          _buildField(
                            context.tr('Jina la Kwanza', en: 'First Name'),
                            _firstNameController,
                            Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? context.tr(
                                    'Jina la kwanza linahitajika',
                                    en: 'First name is required',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          _buildField(
                            context.tr('Jina la Mwisho', en: 'Last Name'),
                            _lastNameController,
                            Icons.person_outline,
                            validator: (v) => null,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildField(
                            context.tr('Barua Pepe', en: 'Email'),
                            _emailController,
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.isEmpty
                                ? context.tr(
                                    'Barua pepe inahitajika',
                                    en: 'Email is required',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Phone (Optional)
                          _buildField(
                            context.tr(
                              'Namba ya Simu (Si lazima)',
                              en: 'Phone Number (Optional)',
                            ),
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
                                  context.tr(
                                    'Nakubali sheria na masharti',
                                    en: 'I accept the terms and conditions',
                                  ),
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
                                  : Text(
                                      context.tr('JISAJILI', en: 'REGISTER'),
                                      style: const TextStyle(
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
                                context.tr(
                                  'Tayari una akaunti?',
                                  en: 'Already have an account?',
                                ),
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
                                  context.tr('Ingia Hapa', en: 'Sign in here'),
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
        labelText: context.tr('Nenosiri', en: 'Password'),
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
        if (value == null || value.isEmpty) {
          return context.tr(
            'Tafadhali weka nenosiri',
            en: 'Please enter your password',
          );
        }
        if (value.length < 6) {
          return context.tr(
            'Nenosiri lazima iwe angalau herufi 6',
            en: 'Password must be at least 6 characters',
          );
        }
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
        labelText: context.tr('Thibitisha Nenosiri', en: 'Confirm Password'),
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
          return context.tr(
            'Tafadhali thibitisha nenosiri',
            en: 'Please confirm your password',
          );
        }
        if (value != _passwordController.text) {
          return context.tr(
            'Nenosiri hazilingani',
            en: 'Passwords do not match',
          );
        }
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
