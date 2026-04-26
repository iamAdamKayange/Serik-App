import 'dart:convert'; // 🔥 ADDED: kwa jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 🔥 ADDED: HTTP requests
import 'package:lottie/lottie.dart';
import 'package:serkapp/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // 🔥 ROLE SELECT
  String _selectedRole = "normal";

  // 🔥 ADDED: NGROK BACKEND BASE URL
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
                    child: Lottie.asset("assets/animations/register.json"),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Undaa Akaunti Mpya',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 30),

                // ROLE SELECT
                Column(
                  children: [
                    RadioListTile(
                      title: const Text("Normal User"),
                      value: "normal",
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    RadioListTile(
                      title: const Text("Landlord"),
                      value: "landlord",
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _buildField("Jina la Kwanza", _firstNameController),
                _buildField("Jina la Mwisho", _lastNameController),
                _buildField("Namba ya Simu", _phoneController),
                _buildField("Barua Pepe", _emailController),

                _buildPasswordField(),
                _buildConfirmPasswordField(),

                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (v) {
                        setState(() => _agreeToTerms = v!);
                      },
                    ),
                    const Expanded(child: Text("Nakubali sheria na masharti")),
                  ],
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _agreeToTerms
                      ? (_isLoading ? null : _registerUser)
                      : null,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("JISAJILI"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 🔥 UPDATED REGISTER LOGIC (NODE JS API)
  // =========================
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"), // 🔥 ADDED: Node API endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "role": _selectedRole, // 🔥 ADDED: role sent to backend
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 🔥 SUCCESS
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );

        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
      } else {
        // 🔥 ERROR FROM SERVER
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Registration failed")),
        );
      }
    } catch (e) {
      // 🔥 NETWORK ERROR
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  // =========================
  // UI HELPERS (NO CHANGE)
  // =========================
  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: "Confirm Password",
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
    );
  }
}
