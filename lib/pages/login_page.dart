import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/pages/home_page.dart';
import 'package:serik/pages/register_page.dart';
import 'package:serik/pages/rental_home_page.dart';
import 'package:serik/services/api_services.dart';
import 'package:serik/services/notification_service.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/widgets/custom_dialogs.dart';

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
        String? avatarUrl = result['profileImageUrl']?.toString() ??
            result['profile_image_url']?.toString();

        authProvider.login(
          userId: userId,
          userName: fullName.isEmpty ? 'User' : fullName,
          userEmail: userEmail,
          userRole: userRole,
          token: result['token'],
          phone: phone,
          avatarUrl: avatarUrl,
        );
        await NotificationService.instance.syncDeviceToken(userId: userId);

        debugPrint('✅ User logged in: $fullName');
        debugPrint('🎭 Role: $userRole');

        CustomDialogs.showSuccess(
          context,
          context.tr(
            'Kuingia kumefanikiwa!',
            en: 'Login successful!',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        if (mounted) {
          if (widget.redirectTo == 'details' && widget.spotId != null) {
            Navigator.pop(context, true);
          } else if (widget.redirectTo == 'verification') {
            Navigator.pop(context, true);
          } else {
            _navigateToHomePage(userRole);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  'Barua pepe au nenosiri si sahihi',
                  en: 'Email or password is incorrect',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('Hitilafu', en: 'Error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
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
        MaterialPageRoute(builder: (_) => const HomePage()),
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

                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Image.asset(
                            'assets/images/seriki.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    context.tr('Karibu Tena!', en: 'Welcome Back!'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'Ingia kwenye akaunti yako',
                      en: 'Sign in to your account',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
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
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 16, color: textColor),
                            decoration: InputDecoration(
                              labelText: context.tr('Barua Pepe', en: 'Email'),
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
                                return context.tr(
                                  'Tafadhali weka barua pepe yako',
                                  en: 'Please enter your email',
                                );
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return context.tr(
                                  'Barua pepe si sahihi',
                                  en: 'Email is invalid',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 16, color: textColor),
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'Nenosiri',
                                en: 'Password',
                              ),
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
                          ),
                          const SizedBox(height: 12),

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
                                    context.tr('Nikumbuke', en: 'Remember me'),
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
                                  context.tr(
                                    'Umesahau nenosiri?',
                                    en: 'Forgot password?',
                                  ),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

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
                                  : Text(
                                      context.tr('INGIA', en: 'SIGN IN'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr(
                                  'Huna akaunti?',
                                  en: 'No account?',
                                ),
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
                                  context.tr(
                                    'Jisajili Sasa',
                                    en: 'Register Now',
                                  ),
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

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🔑 Kama una akaunti ya Mwenye Nyumba, utaelekezwa kwenye Panel yako ya Kusimamia Nyumba.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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

  Future<void> _showForgotPasswordDialog() async {
    final content = await ApiService.getAppContent();
    final supportPhone = content?['supportPhone']?.toString() ?? '+255 629 095 954';
    final supportEmail = content?['supportEmail']?.toString() ?? 'support@serik.co.tz';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('Umesahau Nenosiri?', en: 'Forgot Password?'),
          style: TextStyle(color: textColor),
        ),
        content: Text(
          context.tr(
            'Wasiliana na msimamizi kwa kupiga simu $supportPhone\n\nAu tuma ujumbe kwa $supportEmail',
            en: 'Contact the administrator by calling $supportPhone\n\nOr send a message to $supportEmail',
          ),
          style: TextStyle(color: hintTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('Sawa', en: 'OK'),
              style: TextStyle(color: primaryColor),
            ),
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
