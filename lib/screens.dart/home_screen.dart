import 'package:flutter/material.dart';
import 'package:pos/Core/custom_app_bar.dart';

class HomeScreen extends StatelessWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName, required String title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(context, userName),
      body: const Center(
        child: Text(
          'Welcome to your POS App!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}