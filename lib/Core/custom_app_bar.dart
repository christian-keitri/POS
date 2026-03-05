import 'package:flutter/material.dart';
import 'package:pos/Core/app_state.dart';
import 'package:pos/admin/admin_shell.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/screens.dart/login_screen.dart';

class CustomAppBar {
  static AppBar build(BuildContext context, [String? userName]) {
    final user = AppState.currentUser;
    final displayName = userName ?? user?.name ?? 'Guest';
    final roleLabel = user?.role != null ? ' · ${_roleDisplayName(user!.role)}' : '';
    final role = user?.role?.toLowerCase();
    final canOpenAdmin = role == 'admin' || role == 'manager';
    return AppBar(
      title: Text(
        "Welcome, $displayName$roleLabel",
        style: const TextStyle(
          fontSize: AppTheme.fontSizeHeading,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppTheme.primary,
      elevation: 0,
      actions: [
        if (canOpenAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminShell()),
              );
            },
          ),
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

  static String _roleDisplayName(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'manager': return 'Manager';
      case 'cashier': return 'Cashier';
      default: return role;
    }
  }
}
