import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos/config/api_config.dart';
import 'package:pos/Core/app_state.dart';
import 'package:pos/models/user.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/admin/admin_shell.dart';
import 'package:pos/screens/home_screen.dart';
import 'package:pos/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = body['data'] as Map<String, dynamic>;
        final user = User.fromJson(userData['user'] as Map<String, dynamic>);
        AppState.currentUser = user;
        AppState.authToken = userData['accessToken'] as String?;
        if (!mounted) return;
        final role = user.role.toLowerCase();
        final goToAdmin = role == 'admin' || role == 'manager';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                goToAdmin ? const AdminShell() : const HomeScreen(title: 'POS'),
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        AppSnackBar.error(context, body['error']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, apiErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.sizeOf(context).width > 400
                ? 360
                : double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                  Text("Login", style: AppTheme.displayStyle),
                  const SizedBox(height: 32),

                  /// Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (value) =>
                        value!.isEmpty ? "Enter your email" : null,
                  ),

                  const SizedBox(height: 20),

                  /// Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (value) =>
                        value!.isEmpty ? "Enter your password" : null,
                  ),

                  const SizedBox(height: 32),

                  /// Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Login"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Signup Link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: Text(
                      "Create an account",
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
