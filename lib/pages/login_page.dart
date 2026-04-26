// lib/pages/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:serkapp/pages/register_page.dart';
import 'package:serkapp/pages/rental_home_page.dart';
import 'package:serkapp/services/api_services.dart'; // 🔥 ADDED: ApiService

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 🔥 backend base URL (ngrok)
  final String baseUrl =
      "https://stream-linguist-subzero.ngrok-free.dev/api/auth";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),

                const SizedBox(height: 20),

                Center(
                  child: SizedBox(
                    height: 150,
                    child: Lottie.asset("assets/animations/login1.json"),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Karibu Tena',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 30),

                // PHONE
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Namba ya Simu",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Jaza namba ya simu" : null,
                ),

                const SizedBox(height: 15),

                // PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Nenosiri",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Jaza password" : null,
                ),

                const SizedBox(height: 25),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("INGIA"),
                  ),
                ),

                const SizedBox(height: 20),

                // REGISTER LINK
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text("Huna akaunti? Jisajili"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 🔥 LOGIN FUNCTION - SAVES TOKEN TO ApiService
  // =========================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": _phoneController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 🔥🔥🔥 STEP 1: GET TOKEN FROM RESPONSE 🔥🔥🔥
        final String token = data['token'];

        // 🔥🔥🔥 STEP 2: SAVE TOKEN TO ApiService 🔥🔥🔥
        ApiService.setAuthToken(token);

        debugPrint('✅ Login successful! Token saved.');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RentalHomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
