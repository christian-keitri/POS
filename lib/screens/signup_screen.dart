import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos/config/api_config.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/screens/login_screen.dart';

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

  /// Selected role: admin, manager, or cashier
  String _selectedRole = 'cashier';
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
          'role': _selectedRole,
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
      backgroundColor: AppTheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
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

                  /// Role
                  Text(
                    'Role',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoleChip(
                        label: 'Admin',
                        value: 'admin',
                        selected: _selectedRole == 'admin',
                        onTap: () => setState(() => _selectedRole = 'admin'),
                      ),
                      const SizedBox(width: 10),
                      _RoleChip(
                        label: 'Manager',
                        value: 'manager',
                        selected: _selectedRole == 'manager',
                        onTap: () => setState(() => _selectedRole = 'manager'),
                      ),
                      const SizedBox(width: 10),
                      _RoleChip(
                        label: 'Cashier',
                        value: 'cashier',
                        selected: _selectedRole == 'cashier',
                        onTap: () => setState(() => _selectedRole = 'cashier'),
                      ),
                    ],
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
                        value!.length < 8 ? "Minimum 8 characters" : null,
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

class _RoleChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

