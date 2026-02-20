import 'package:flutter/material.dart';

class CustomAppBar {
  static AppBar build(String? userName) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome,", style: TextStyle(fontSize: 16)),
          Text(
            userName ?? "Guest", // fallback if null
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFF2400),
      elevation: 4,
    );
  }
}
