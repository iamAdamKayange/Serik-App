// lib/pages/otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:serkapp/pages/rental_home_page.dart';
import 'package:serkapp/services/api_services.dart'; // 🔥 ADDED: ApiService

class OTPVerificationPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OTPVerificationPage({super.key, required this.userData});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _countdown = 60;
  bool _canResend = false;

  // 🔥 OTP from backend (you'll get this from API)
  // ignore: unused_field
  String _generatedOTP = '';
  // ignore: unused_field
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _setupFocusListeners();
    _sendOTP(); // 🔥 Send OTP when page loads
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _otpControllers[i].text.isEmpty) {
          if (i > 0) _focusNodes[i - 1].requestFocus();
        }
      });
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
            _startCountdown();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  // 🔥 NEW: Send OTP to backend
  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phone = widget.userData['phone']?.toString() ?? '';

      // Call your backend to send OTP
      // This depends on your backend implementation
      final response = await ApiService.sendOTP(phone);

      if (response != null && response['success'] == true) {
        _generatedOTP = response['otp'] ?? '123456'; // For testing only
        _otpSent = true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP imetumwa kwenye simu yako"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to send OTP");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu katika kutuma OTP: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🔥 NEW: Resend OTP
  Future<void> _resendOTP() async {
    setState(() {
      _countdown = 60;
      _canResend = false;
      _isLoading = true;
    });

    _startCountdown();

    try {
      final phone = widget.userData['phone']?.toString() ?? '';
      final response = await ApiService.sendOTP(phone);

      if (response != null && response['success'] == true) {
        _generatedOTP = response['otp'] ?? '123456';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP imetumwa tena kwenye simu yako"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to resend OTP");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu katika kutuma OTP tena: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _enteredOTP =>
      _otpControllers.map((controller) => controller.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 20),

              // Animation
              Center(
                child: SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    "assets/animations/otp.json",
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Info
              Text(
                'Thibitisha Namba Yako',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tumetuma namba ya tarakimu 6 kwenye simu yako',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatPhoneNumber(widget.userData['phone']?.toString() ?? ''),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),

              // OTP Inputs
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _focusNodes[index].hasFocus
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.length == 1) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Timer
              Center(
                child: Text(
                  '$_countdown sekunde zimebaki',
                  style: TextStyle(
                    color: _canResend ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: _canResend && !_isLoading ? _resendOTP : null,
                  child: Text(
                    'Tuma OTP tena',
                    style: TextStyle(
                      color: _canResend && !_isLoading
                          ? Colors.blue
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Verify Button
              FilledButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Thibitisha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Help
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Ukishindwa kupokea OTP, hakikisha umeweka namba sahihi ya simu na ujaribu tena",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    if (!cleaned.startsWith('255')) {
      cleaned = '255$cleaned';
    }
    return '+$cleaned';
  }

  // 🔥 MODIFIED: Verify OTP with backend
  Future<void> _verifyOTP() async {
    String otp = _enteredOTP;

    if (otp.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Weka OTP kamili")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 Verify OTP with backend
      final phone = widget.userData['phone']?.toString() ?? '';
      final verificationResult = await ApiService.verifyOTP(phone, otp);

      if (!verificationResult) {
        throw Exception("OTP si sahihi au imeisha");
      }

      // 🔥 Register user with backend
      final registrationResult = await ApiService.register(widget.userData);

      if (registrationResult == null) {
        throw Exception("Failed to register user");
      }

      // 🔥 Save token for future requests
      if (registrationResult['token'] != null) {
        ApiService.setAuthToken(registrationResult['token']);
      }

      // SUCCESS
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Usajili umekamilika kikamilifu!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RentalHomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hitilafu: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
