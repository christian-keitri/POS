import 'package:flutter/material.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/models/order.dart';
import 'package:pos/models/user.dart';
import 'package:pos/screens/order_detail_screen.dart';

/// Sales management: list transactions, filters (date, user, product), edit/void, receipts.
class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {
  List<Order> _orders = [];
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  int? _userIdFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
        ApiService.getOrders(
          userId: _userIdFilter,
          status: _statusFilter,
        ),
        ApiService.getUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<Order>;
        _users = results[1] as List<User>;
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

  List<Order> get _filteredOrders {
    var list = _orders;
    if (_dateFrom != null) {
      list = list.where((o) {
        final created = DateTime.tryParse(o.createdAt);
        return created != null && !created.isBefore(_dateFrom!);
      }).toList();
    }
    if (_dateTo != null) {
      list = list.where((o) {
        final created = DateTime.tryParse(o.createdAt);
        if (created == null) return false;
        final end = DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59);
        return !created.isAfter(end);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales & Transactions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('Status'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _load();
                    },
                  ),
                  DropdownButton<int?>(
                    value: _userIdFilter,
                    hint: const Text('User'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All users')),
                      ..._users.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _userIdFilter = v);
                      _load();
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (range != null) {
                        setState(() {
                          _dateFrom = range.start;
                          _dateTo = range.end;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(_dateFrom == null
                        ? 'Pick date range'
                        : '${_dateFrom!.toString().substring(0, 10)} – ${_dateTo?.toString().substring(0, 10) ?? ""}'),
                  ),
                  if (_dateFrom != null || _dateTo != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _dateFrom = null;
                        _dateTo = null;
                      }),
                      child: const Text('Clear dates'),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : _OrdersTable(
                      orders: _filteredOrders,
                      onView: _viewOrder,
                      onReceipt: _showReceipt,
                      onVoid: _voidOrder,
                      onRefresh: _load,
                    ),
        ),
      ],
    );
  }

  void _viewOrder(Order order) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: order.id),
      ),
    );
    if (updated == true && mounted) _load();
  }

  Future<void> _showReceipt(Order order) async {
    try {
      final data = await ApiService.getReceipt(order.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Receipt #${order.orderNumber ?? order.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${order.createdAt}'),
                Text('Status: ${order.status}'),
                Text('Total: \$${order.total.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                const Divider(),
                ...(data['items'] as List<dynamic>? ?? []).map((e) {
                  final m = e as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${m['product_name']} x${m['quantity']} — \$${(m['subtotal'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                // Placeholder: print or share receipt
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Print/export receipt (connect to printer or share)')),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Print / Export'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _voidOrder(Order order) async {
    if (order.status == 'cancelled') return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transaction'),
        content: Text(
          'Void order #${order.orderNumber ?? order.id}? This will set status to cancelled.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.updateOrderStatus(order.id, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order voided')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<Order> orders;
  final void Function(Order) onView;
  final void Function(Order) onReceipt;
  final void Function(Order) onVoid;
  final VoidCallback onRefresh;

  const _OrdersTable({
    required this.orders,
    required this.onView,
    required this.onReceipt,
    required this.onVoid,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;
    if (isNarrow) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('#${o.orderNumber ?? o.id}'),
                subtitle: Text(
                  '${o.createdAt} · \$${o.total.toStringAsFixed(2)} · ${o.status}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'view') onView(o);
                    if (v == 'receipt') onReceipt(o);
                    if (v == 'void') onVoid(o);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'view', child: Text('View')),
                    const PopupMenuItem(value: 'receipt', child: Text('Receipt')),
                    if (o.status != 'cancelled')
                      const PopupMenuItem(value: 'void', child: Text('Void')),
                  ],
                ),
                onTap: () => onView(o),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Order')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions'), numeric: true),
          ],
          rows: orders.map((o) {
            return DataRow(
              cells: [
                DataCell(Text('#${o.orderNumber ?? o.id}')),
                DataCell(Text(o.createdAt.length >= 10 ? o.createdAt.substring(0, 10) : o.createdAt)),
                DataCell(Text('\$${o.total.toStringAsFixed(2)}')),
                DataCell(Chip(
                  label: Text(o.status),
                  backgroundColor: _statusColor(o.status).withValues(alpha: 0.2),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => onView(o),
                      child: const Text('View'),
                    ),
                    TextButton(
                      onPressed: () => onReceipt(o),
                      child: const Text('Receipt'),
                    ),
                    if (o.status != 'cancelled')
                      IconButton(
                        icon: Icon(Icons.cancel_rounded, color: AppTheme.error),
                        onPressed: () => onVoid(o),
                        tooltip: 'Void',
                      ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppTheme.success;
      case 'pending': return AppTheme.primary;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.textSecondary;
    }
  }
}
