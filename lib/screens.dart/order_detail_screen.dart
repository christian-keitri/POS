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
  bool _updating = false;

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
      setState(() => _updating = true);
      await ApiService.updateOrderStatus(widget.orderId, status);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _editPaymentAndNotes() async {
    if (_order == null) return;
    final notesController = TextEditingController(text: _order!.notes ?? '');
    String? selectedPayment = _order!.paymentMethod;
    if (selectedPayment != null && selectedPayment.isEmpty) selectedPayment = null;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Payment & notes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPayment,
                    decoration: const InputDecoration(labelText: 'Payment method'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Not set')),
                      ...['Cash', 'Card', 'Mobile', 'Other']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: (v) => setDialogState(() => selectedPayment = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes', hintText: 'Table, comment…'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (result != true || !mounted) return;
    try {
      setState(() => _updating = true);
      await ApiService.updateOrder(
        widget.orderId,
        paymentMethod: selectedPayment,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (mounted) {
        AppSnackBar.success(context, 'Order updated');
        _load();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _updating = false);
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
                          Row(
                            children: [
                              _buildStatusChip(_order!.status),
                              const Spacer(),
                              if (_order!.status == 'pending')
                                TextButton.icon(
                                  onPressed: _updating ? null : _editPaymentAndNotes,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created ${_order!.createdAt}',
                            style: AppTheme.captionStyle,
                          ),
                          if (_order!.updatedAt != null && _order!.updatedAt!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Updated ${_order!.updatedAt}',
                              style: AppTheme.captionStyle,
                            ),
                          ],
                          if (_order!.paymentMethod != null && _order!.paymentMethod!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.payment_rounded, size: 18, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text('Payment: ${_order!.paymentMethod}', style: AppTheme.bodySecondaryStyle),
                              ],
                            ),
                          ],
                          if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note_rounded, size: 18, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_order!.notes!, style: AppTheme.bodySecondaryStyle)),
                              ],
                            ),
                          ],
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
                                  child: OutlinedButton.icon(
                                    onPressed: _updating ? null : () => _updateStatus('cancelled'),
                                    icon: const Icon(Icons.cancel_outlined, size: 20),
                                    label: const Text('Cancel Order'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _updating ? null : () => _updateStatus('completed'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    label: const Text('Complete'),
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
