import 'package:flutter/material.dart';
import 'package:pos/core/app_state.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/screens.dart/login_screen.dart';

class CustomAppBar {
  static AppBar build(BuildContext context, [String? userName]) {
    final displayName = userName ?? AppState.currentUser?.displayName ?? 'Guest';
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome,",
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeHeading,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.appBarBackground,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () {
            AppState.currentUser = null;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
