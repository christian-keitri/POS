import 'package:flutter/material.dart';
import 'package:pos/Core/custom_app_bar.dart';
import 'package:pos/Core/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName, required String title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<NavItem> navItems = [
    NavItem(icon: Icons.home, label: 'Home', index: 0),
    NavItem(icon: Icons.shopping_cart, label: 'Orders', index: 1),
    NavItem(icon: Icons.inventory, label: 'Products', index: 2),
    NavItem(icon: Icons.person, label: 'Profile', index: 3),
  ];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildHomeContent(),
      _buildOrdersContent(),
      _buildProductsContent(),
      _buildProfileContent(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(context, widget.userName),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
        activeColor: const Color(0xFFFFD700),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHomeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 16),
          const Text(
            'Welcome to your POS App!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hello, ${widget.userName ?? "User"}!',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 16),
          const Text(
            'Orders',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your orders here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 16),
          const Text(
            'Products',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'View and manage your products',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 16),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'View your profile settings',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}