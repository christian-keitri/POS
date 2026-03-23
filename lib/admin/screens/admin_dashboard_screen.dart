import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/reports.dart';
import 'package:pos/Core/app_state.dart';

/// Dashboard: sales metrics (daily/weekly/monthly), quick stats, charts.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Product>? _lowStockProducts;
  int? _userCount;
  SalesReport? _salesReport;
  SalesReport? _salesReportWeekly;
  SalesReport? _salesReportMonthly;
  Map<String, dynamic>? _revenueAnalytics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getOrderStats(userId: AppState.currentUser?.id),
        ApiService.getLowStockAlerts(),
        ApiService.getUsers(),
        ApiService.getSalesReport(period: 'daily'),
        ApiService.getSalesReport(period: 'weekly'),
        ApiService.getSalesReport(period: 'monthly'),
        ApiService.getRevenueAnalytics(period: 'daily', days: 14)
            .catchError((_) => <String, dynamic>{}),
      ]);

      if (!mounted) return;
      setState(() {
        _lowStockProducts = results[1] as List<Product>;
        _userCount = (results[2] as List).length;
        _salesReport = results[3] as SalesReport;
        _salesReportWeekly = results[4] as SalesReport;
        _salesReportMonthly = results[5] as SalesReport;
        _revenueAnalytics = results[6] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 24),

                // Quick stats
                _QuickStats(
                  lowStockCount: _lowStockProducts?.length ?? 0,
                  userCount: _userCount ?? 0,
                  salesReportDaily: _salesReport,
                  salesReportWeekly: _salesReportWeekly,
                  salesReportMonthly: _salesReportMonthly,
                ),
                const SizedBox(height: 24),

                // Charts row
                if (isNarrow) ...[
                  _SalesChartCard(salesReport: _salesReport, revenue: _revenueAnalytics),
                  const SizedBox(height: 16),
                  _PaymentPieCard(salesReport: _salesReport),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _SalesChartCard(salesReport: _salesReport, revenue: _revenueAnalytics),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _PaymentPieCard(salesReport: _salesReport),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Low stock alerts
                if ((_lowStockProducts?.length ?? 0) > 0) ...[
                  Text(
                    'Low stock alerts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lowStockProducts!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = _lowStockProducts![i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.error.withValues(alpha: 0.2),
                            child: Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                          ),
                          title: Text(p.name),
                          subtitle: Text('Stock: ${p.stock} (threshold: ${p.lowStockThreshold})'),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final int lowStockCount;
  final int userCount;
  final SalesReport? salesReportDaily;
  final SalesReport? salesReportWeekly;
  final SalesReport? salesReportMonthly;

  const _QuickStats({
    required this.lowStockCount,
    required this.userCount,
    this.salesReportDaily,
    this.salesReportWeekly,
    this.salesReportMonthly,
  });

  @override
  Widget build(BuildContext context) {
    final dailyRevenue = salesReportDaily?.totalRevenue ?? 0.0;
    final weeklyRevenue = salesReportWeekly?.totalRevenue ?? 0.0;
    final monthlyRevenue = salesReportMonthly?.totalRevenue ?? 0.0;

    final stats = [
      _StatItem('Daily sales', '\$${dailyRevenue.toStringAsFixed(2)}', Icons.today_rounded, AppTheme.primary),
      _StatItem('Weekly sales', '\$${weeklyRevenue.toStringAsFixed(2)}', Icons.date_range_rounded, AppTheme.primaryDark),
      _StatItem('Monthly (est.)', '\$${monthlyRevenue.toStringAsFixed(2)}', Icons.calendar_month_rounded, AppTheme.primary),
      _StatItem('Low stock items', '$lowStockCount', Icons.inventory_2_outlined, lowStockCount > 0 ? AppTheme.error : AppTheme.success),
      _StatItem('Active users', '$userCount', Icons.people_rounded, AppTheme.success),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < 600;

        if (isNarrow) {
          // Single column: cards stack vertically with consistent spacing
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                _StatCard(item: stats[i]),
                if (i < stats.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        // Tablet/desktop: responsive grid
        final crossAxisCount = width > 900 ? 3 : 2;
        final spacing = 16.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.35,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _StatCard(item: stats[index]),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: 32),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: AppTheme.captionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  final SalesReport? salesReport;
  final Map<String, dynamic>? revenue;

  const _SalesChartCard({this.salesReport, this.revenue});

  @override
  Widget build(BuildContext context) {
    final daily = salesReport?.dailyBreakdown ?? [];
    final spots = daily.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList();
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, meta) => Text(
                          '\$${v.toInt()}',
                          style: AppTheme.smallStyle,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i >= 0 && i < daily.length) {
                            final d = daily[i].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                d.length >= 10 ? d.substring(5, 10) : d,
                                style: AppTheme.smallStyle,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: 0,
                  maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1).clamp(1.0, double.infinity),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPieCard extends StatelessWidget {
  final SalesReport? salesReport;

  const _PaymentPieCard({this.salesReport});

  @override
  Widget build(BuildContext context) {
    final methods = salesReport?.paymentMethods ?? [];
    if (methods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment methods',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                height: 220,
                child: Center(child: Text('No data')),
              ),
            ],
          ),
        ),
      );
    }

    final colors = [
      AppTheme.primary,
      AppTheme.primaryDark,
      AppTheme.success,
      AppTheme.textSecondary,
    ];
    final sections = methods.asMap().entries.map((e) {
      return PieChartSectionData(
        value: e.value.total,
        title: e.value.methodDisplay,
        color: colors[e.key % colors.length],
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
