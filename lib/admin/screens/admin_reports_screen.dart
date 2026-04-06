import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/models/reports.dart';

/// Reports & analytics: sales trends, inventory trends, export placeholders.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  String? _error;
  SalesReport? _salesReport;
  List<TopProduct> _topProducts = [];
  Map<String, dynamic>? _revenueAnalytics;
  Map<String, dynamic>? _inventoryReport;

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
      final sales = ApiService.getSalesReport(period: 'daily');
      final topProducts = ApiService.getTopProducts(period: 'monthly', limit: 10);
      final revenue = ApiService.getRevenueAnalytics(period: 'daily', days: 14)
          .catchError((_) => <String, dynamic>{});
      final inventory = ApiService.getInventoryReport();

      final results = await Future.wait([sales, topProducts, revenue, inventory]);

      if (!mounted) return;
      setState(() {
        _salesReport = results[0] as SalesReport;
        _topProducts = results[1] as List<TopProduct>;
        _revenueAnalytics = results[2] as Map<String, dynamic>?;
        _inventoryReport = results[3] as Map<String, dynamic>?;
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary)),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reports & Analytics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportCsvPlaceholder,
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Export CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportPdfPlaceholder,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Export PDF'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sales trend chart (using revenue analytics)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales trend (daily)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: _SalesTrendChart(revenueData: _revenueAnalytics),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top products (bar)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top products (revenue)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: _TopProductsBarChart(topProducts: _topProducts),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Summary cards
          Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'Total revenue',
                    value: '\$${_salesReport?.totalRevenue.toStringAsFixed(2) ?? '0.00'}',
                    icon: Icons.trending_up_rounded,
                  ),
                  _SummaryCard(
                    title: 'Orders',
                    value: '${_salesReport?.totalOrders ?? 0}',
                    icon: Icons.shopping_cart_rounded,
                  ),
                  _SummaryCard(
                    title: 'Avg. order value',
                    value: '\$${_salesReport?.averageOrderValue.toStringAsFixed(2) ?? '0.00'}',
                    icon: Icons.receipt_long_rounded,
                  ),
                ],
            ),
          const SizedBox(height: 24),

          // Inventory summary
          if (_inventoryReport != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final summary = _inventoryReport!['summary'] as Map<String, dynamic>?;
                      if (summary == null) return const Text('No data');
                      return Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          Text('Products: ${summary['totalProducts'] ?? 0}', style: AppTheme.bodySecondaryStyle),
                          Text('Stock value: \$${(summary['totalStockValue'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: AppTheme.bodySecondaryStyle),
                          Text('Low stock: ${summary['lowStockCount'] ?? 0}', style: AppTheme.bodySecondaryStyle),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _exportCsvPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV: connect to backend export endpoint or generate client-side CSV')),
    );
  }

  void _exportPdfPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export PDF: connect to backend PDF generation or use a PDF package')),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  final Map<String, dynamic>? revenueData;

  const _SalesTrendChart({required this.revenueData});

  @override
  Widget build(BuildContext context) {
    final dataList = (revenueData?['data'] as List<dynamic>?) ?? [];
    final spots = dataList
        .asMap()
        .entries
        .map((e) {
          final entry = e.value as Map<String, dynamic>;
          return FlSpot(e.key.toDouble(), (entry['revenue'] as num?)?.toDouble() ?? 0);
        })
        .toList();
    if (spots.isEmpty) spots.add(const FlSpot(0, 0));
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
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
                if (i >= 0 && i < dataList.length) {
                  final entry = dataList[i] as Map<String, dynamic>;
                  final d = entry['period']?.toString() ?? '';
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
        maxY: maxY.clamp(1.0, double.infinity),
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
    );
  }
}

class _TopProductsBarChart extends StatelessWidget {
  final List<TopProduct> topProducts;

  const _TopProductsBarChart({required this.topProducts});

  @override
  Widget build(BuildContext context) {
    if (topProducts.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final maxRevenue = topProducts.map((p) => p.totalRevenue).reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue * 1.1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i >= 0 && i < topProducts.length) {
                  final name = topProducts[i].name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 12 ? '${name.substring(0, 12)}…' : name,
                      style: AppTheme.smallStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(
                '\$${v.toInt()}',
                style: AppTheme.smallStyle,
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: topProducts.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.totalRevenue,
                color: AppTheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.captionStyle),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
