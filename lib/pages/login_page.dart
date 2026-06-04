import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/pages/normal_user_homepage.dart';
import 'package:serkapp/pages/register_page.dart';
import 'package:serkapp/pages/rental_home_page.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/providers/auth_provider.dart';
import 'package:serkapp/providers/theme_provider.dart';

class LoginPage extends StatefulWidget {
  final String? redirectTo;
  final String? spotId;

  const LoginPage({super.key, this.redirectTo, this.spotId});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Helper getters for theme colors
  bool get isDarkMode =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  Color get surfaceColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color? get hintTextColor => isDarkMode ? Colors.grey[500] : Colors.grey[600];
  Color get inputFillColor => isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
  Color get borderColor => isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
  Color get primaryColor =>
      isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);

  List<Color> get gradientColors => isDarkMode
      ? [const Color(0xFF1B5E20), const Color(0xFF0D3B0F)]
      : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    // Load saved email if any
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('📡 Logging in with ApiService...');
      debugPrint('📧 Email: ${_emailController.text.trim()}');

      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result != null && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        String userId = result['id']?.toString() ?? '';
        String userEmail = result['email'] ?? _emailController.text.trim();
        String userRole = result['role'] ?? 'normal';
        String firstName = result['firstName'] ?? '';
        String lastName = result['lastName'] ?? '';
        String fullName = '$firstName $lastName'.trim();
        String? phone = result['phone'];

        authProvider.login(
          userId: userId,
          userName: fullName.isEmpty ? 'User' : fullName,
          userEmail: userEmail,
          userRole: userRole,
          token: result['token'],
          phone: phone,
        );

        debugPrint('✅ User logged in: $fullName');
        debugPrint('🎭 Role: $userRole');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuingia kumefanikiwa!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (widget.redirectTo == 'details' && widget.spotId != null) {
          Navigator.pop(context, true);
        } else {
          _navigateToHomePage(userRole);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barua pepe au nenosiri si sahihi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  void _navigateToHomePage(String role) {
    if (role == 'landlord' || role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RentalHomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NormalUserHomepage()),
      );
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
                  // Back Button Only (No Dark Mode Toggle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
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
                      height: 180,
                      child: Lottie.asset(
                        "assets/animations/login1.json",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome Text
                  Text(
                    'Karibu Tena!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingia kwenye akaunti yako',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
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
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 16, color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Barua Pepe',
                              labelStyle: TextStyle(color: hintTextColor),
                              hintText: 'mwananchi@serikapp.com',
                              hintStyle: TextStyle(color: hintTextColor),
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: primaryColor,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tafadhali weka barua pepe yako';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Barua pepe si sahihi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 16, color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Nenosiri',
                              labelStyle: TextStyle(color: hintTextColor),
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: primaryColor,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tafadhali weka nenosiri';
                              }
                              if (value.length < 6) {
                                return 'Nenosiri lazima iwe angalau herufi 6';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) => setState(
                                      () => _rememberMe = value ?? false,
                                    ),
                                    activeColor: primaryColor,
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[400]!,
                                    ),
                                  ),
                                  Text(
                                    'Nikumbuke',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _showForgotPasswordDialog(),
                                child: Text(
                                  'Umesahau nenosiri?',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'INGIA',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Huna akaunti?',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                ),
                                child: Text(
                                  'Jisajili Sasa',
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

                  // Role Info Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🔑 Kama una akaunti ya Mwenye Nyumba, utaelekezwa kwenye Panel yako ya Kusimamia Nyumba.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Umesahau Nenosiri?', style: TextStyle(color: textColor)),
        content: Text(
          'Wasiliana na msimamizi kwa kupiga simu +255 629 095 954\n\n'
          'Au tuma ujumbe kwa support@serikapp.com',
          style: TextStyle(color: hintTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Sawa', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
