import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/screens.dart/login_screen.dart';

class CustomAppBar {
  static AppBar build(BuildContext context, String? userName) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome,", style: TextStyle(fontSize: 16, color: Colors.white70)),
          Text(
            userName ?? "Guest",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 2, 13, 110),
      elevation: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            try {
              await Supabase.instance.client.auth.signOut();

              // Navigate to login screen after logout
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}