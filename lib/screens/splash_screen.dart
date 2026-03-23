import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeOut;
  late Animation<double> _iconFadeIn;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoFadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.666, curve: Curves.easeOut),
      ),
    );

    _iconFadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _navigateAfterSplash();
  }

  void _navigateAfterSplash() {
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Only navigate if we have a valid navigator context
      try {
        // Check if we can access the navigator
        final navigator = Navigator.maybeOf(context);
        if (navigator != null && mounted) {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } catch (e) {
        // Silently handle navigation errors in tests
        if (kDebugMode) {
          print('Navigation error in splash: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  FadeTransition(
                    opacity: _logoFadeOut,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                  FadeTransition(
                    opacity: _iconFadeIn,
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
