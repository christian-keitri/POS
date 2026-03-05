import 'package:flutter/foundation.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/reports.dart';
import 'package:pos/core/app_state.dart';

/// Example state management for the admin dashboard using [ChangeNotifier].
/// Register above [AdminShell] with [ChangeNotifierProvider] and use
/// `context.watch<AdminDashboardProvider>()` or `context.read<AdminDashboardProvider>()`
/// in [AdminDashboardScreen]. Alternatively use Riverpod or Bloc for more complex flows.
class AdminDashboardProvider extends ChangeNotifier {
  Map<String, dynamic>? _orderStats;
  List<Product>? _lowStockProducts;
  int? _userCount;
  SalesReport? _salesReport;
  Map<String, dynamic>? _revenueAnalytics;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? get orderStats => _orderStats;
  List<Product>? get lowStockProducts => _lowStockProducts;
  int? get userCount => _userCount;
  SalesReport? get salesReport => _salesReport;
  Map<String, dynamic>? get revenueAnalytics => _revenueAnalytics;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getOrderStats(userId: AppState.currentUser?.id),
        ApiService.getLowStockAlerts(),
        ApiService.getUsers(),
        ApiService.getSalesReport(period: 'daily'),
        ApiService.getRevenueAnalytics(period: 'daily', days: 14).catchError((_) => <String, dynamic>{}),
      ]);
      _orderStats = results[0] as Map<String, dynamic>;
      _lowStockProducts = results[1] as List<Product>;
      _userCount = (results[2] as List).length;
      _salesReport = results[3] as SalesReport;
      _revenueAnalytics = results[4] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
