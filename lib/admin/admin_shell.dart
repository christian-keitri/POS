import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/admin/admin_router.dart';
import 'package:pos/screens/home_screen.dart';
import 'package:pos/theme/app_theme.dart';

/// Responsive admin shell: Drawer on mobile, NavigationRail on tablet/desktop.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const double _railBreakpoint = 600;
  late final GoRouter _router = createAdminRouter();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _useRail => MediaQuery.sizeOf(context).width >= _railBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.appBarBackground,
        foregroundColor: Colors.white,
        leading: _useRail
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: 'Back to POS',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(title: 'POS'),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _useRail ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (_useRail) _buildRail(context),
          Expanded(
            child: Material(
              color: AppTheme.background,
              child: Router(
                routerDelegate: _router.routerDelegate,
                routeInformationParser: _router.routeInformationParser,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    final loc = _router.routerDelegate.currentConfiguration.fullPath;
    final selectedIndex = adminRouteToIndex(loc);

    return NavigationRail(
      extended: MediaQuery.sizeOf(context).width >= 800,
      backgroundColor: AppTheme.surfaceElevated,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        _router.go(adminIndexToPath(index));
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_rounded),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_rounded),
          label: Text('Products'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.point_of_sale_rounded),
          label: Text('Sales'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_rounded),
          label: Text('Reports'),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final loc = _router.routerDelegate.currentConfiguration.fullPath;
    final selectedIndex = adminRouteToIndex(loc);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.appBarBackground),
            child: Text(
              'Admin Panel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _navTile(context, 0, Icons.dashboard_rounded, 'Dashboard', selectedIndex),
          _navTile(context, 1, Icons.people_rounded, 'Users', selectedIndex),
          _navTile(context, 2, Icons.inventory_2_rounded, 'Products', selectedIndex),
          _navTile(context, 3, Icons.point_of_sale_rounded, 'Sales', selectedIndex),
          _navTile(context, 4, Icons.analytics_rounded, 'Reports', selectedIndex),
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    int selectedIndex,
  ) {
    final selected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? AppTheme.primary : null),
      title: Text(label),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        _router.go(adminIndexToPath(index));
      },
    );
  }
}
