import 'package:go_router/go_router.dart';
import 'package:pos/admin/screens/admin_dashboard_screen.dart';
import 'package:pos/admin/screens/admin_users_screen.dart';
import 'package:pos/admin/screens/admin_products_screen.dart';
import 'package:pos/admin/screens/admin_sales_screen.dart';
import 'package:pos/admin/screens/admin_reports_screen.dart';

/// Admin panel route paths. Used by shell for navigation and highlighting.
abstract class AdminRoutes {
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String products = '/products';
  static const String sales = '/sales';
  static const String reports = '/reports';

  static const List<String> all = [dashboard, users, products, sales, reports];
}

/// Returns the index for [path] for NavigationRail/Drawer selection.
int adminRouteToIndex(String path) {
  final i = AdminRoutes.all.indexOf(path);
  return i >= 0 ? i : 0;
}

String adminIndexToPath(int index) {
  if (index >= 0 && index < AdminRoutes.all.length) {
    return AdminRoutes.all[index];
  }
  return AdminRoutes.dashboard;
}

GoRouter createAdminRouter() {
  return GoRouter(
    initialLocation: AdminRoutes.dashboard,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => AdminRoutes.dashboard,
      ),
      GoRoute(
        path: AdminRoutes.dashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AdminRoutes.users,
        builder: (_, __) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AdminRoutes.products,
        builder: (_, __) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: AdminRoutes.sales,
        builder: (_, __) => const AdminSalesScreen(),
      ),
      GoRoute(
        path: AdminRoutes.reports,
        builder: (_, __) => const AdminReportsScreen(),
      ),
    ],
  );
}
