import 'package:flutter/material.dart';
import 'package:pos/models/order.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/theme/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

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
      final o = await ApiService.getOrder(widget.orderId);
      if (mounted) setState(() {
        _order = o;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ApiService.updateOrderStatus(widget.orderId, status);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: AppTheme.appBarBackground,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: AppTheme.bodySecondaryStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusChip(_order!.status),
                          const SizedBox(height: 8),
                          Text(
                            'Created ${_order!.createdAt}',
                            style: AppTheme.captionStyle,
                          ),
                          const SizedBox(height: 24),
                          Text('Items', style: AppTheme.titleStyle),
                          const SizedBox(height: 8),
                          ..._order!.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName, style: AppTheme.bodyStyle),
                                          Text(
                                            '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                            style: AppTheme.captionStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: AppTheme.titleStyle),
                              Text(
                                '\$${_order!.total.toStringAsFixed(2)}',
                                style: AppTheme.titleStyle.copyWith(color: AppTheme.primary),
                              ),
                            ],
                          ),
                          if (_order!.status == 'pending') ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateStatus('cancelled'),
                                    child: const Text('Cancel Order'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _updateStatus('completed'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Complete'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppTheme.success;
        break;
      case 'cancelled':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.smallStyle.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
