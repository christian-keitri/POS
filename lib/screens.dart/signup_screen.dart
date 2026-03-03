import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos/config/api_config.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/screens.dart/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      AppSnackBar.error(context, 'Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'business_name': _businessController.text.trim().isEmpty
              ? null
              : _businessController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        AppSnackBar.success(context, 'Account created! You can now log in.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        AppSnackBar.error(context, body['error']?.toString() ?? 'Signup failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Cannot reach server: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Create POS Account",
                    style: AppTheme.titleStyle,
                  ),
                  const SizedBox(height: 32),

                  /// Business Name
                  TextFormField(
                    controller: _businessController,
                    decoration: const InputDecoration(
                      labelText: "Business Name",
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter business name" : null,
                  ),

                  const SizedBox(height: 20),

                  /// Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Enter email" : null,
                  ),

                  const SizedBox(height: 20),

                  /// Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                    ),
                    validator: (value) =>
                        value!.length < 6 ? "Minimum 6 characters" : null,
                  ),

                  const SizedBox(height: 20),

                  /// Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Confirm your password" : null,
                  ),

                  const SizedBox(height: 32),

                  /// Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Sign Up"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Back to Login
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Already have an account? Login",
                      style: AppTheme.captionStyle.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
