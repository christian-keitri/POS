import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/models/order.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/screens/cart_screen.dart';

// 2026 POS order detail palette: soft neutrals + vibrant accent
const Color _neutralBg = Color(0xFFF0F2F5);
const Color _surface = Color(0xFFFFFFFF);
const Color _surfaceSoft = Color(0xFFF8F9FC);
const Color _accent = Color(0xFFD4A017);
const Color _accentDark = Color(0xFFB8860B);
const Color _textPrimary = Color(0xFF1A1D24);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textMuted = Color(0xFF9CA3AF);
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _errorColor = Color(0xFFEF4444);

/// 2026-style POS order detail: fintech/retail inspired, neumorphism, microinteractions.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with TickerProviderStateMixin {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _updating = false;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _load();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await ApiService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = o;
          _loading = false;
        });
        _staggerController.forward(); // drives future stagger if needed
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString();
        _loading = false;
      });
      }
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
                    initialValue: selectedPayment,
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
                style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (result != true || !mounted) {
      notesController.dispose();
      return;
    }
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
      notesController.dispose();
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutralBg,
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _order == null
                  ? const SizedBox.shrink()
                  : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: _accent,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          Text('Loading order…', style: TextStyle(color: _textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: _textMuted),
            const SizedBox(height: 20),
            Text('Couldn’t load order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
            const SizedBox(height: 8),
            Text(_error!.replaceFirst('Exception: ', ''), style: TextStyle(color: _textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
        FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final o = _order!;
    final statusLabel = _statusLabel(o.status);
    final statusColor = _statusColor(o.status);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(o),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _OrderSummaryCard(
                  orderNumber: o.id,
                  customerName: o.notes?.isNotEmpty == true ? o.notes! : 'Walk-in',
                  dateTime: o.createdAt,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  onEdit: o.status == 'pending' ? () => _editPaymentAndNotes() : null,
                  updating: _updating,
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Items', count: o.items.length),
                const SizedBox(height: 12),
                ...o.items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(item.id),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (i * 80)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _ItemCard(
                      productName: item.productName,
                      quantity: item.quantity,
                      unitPrice: item.unitPrice,
                      subtotal: item.subtotal,
                    ),
                  );
                }),
                const SizedBox(height: 20),
                _TotalCard(amount: o.total),
                const SizedBox(height: 20),
                _PaymentRow(paymentMethod: o.paymentMethod),
                const SizedBox(height: 28),
                _ActionButtons(
                  order: o,
                  onRepeat: () => _onRepeatOrder(o),
                  onRefund: () => _onRefund(),
                  onPrint: () => _onPrint(),
                  onComplete: o.status == 'pending' ? () => _updateStatus('completed') : null,
                  onCancel: o.status == 'pending' ? () => _updateStatus('cancelled') : null,
                  updating: _updating,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(Order o) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: _surface,
      elevation: 0,
      scrolledUnderElevation: 8,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _neutralBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Order #${o.id}',
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'In Progress';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return _success;
      case 'cancelled':
        return _errorColor;
      default:
        return _warning;
    }
  }

  void _onRepeatOrder(Order o) {
    // Navigate to cart; in a full app you could prefill cart from order items
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    AppSnackBar.show(context, 'Create a new order with the same items in Cart');
  }

  void _onRefund() {
    AppSnackBar.show(context, 'Refund flow coming soon');
  }

  void _onPrint() {
    AppSnackBar.show(context, 'Print / Share receipt coming soon');
  }
}

// ─── Order summary card (top) ─────────────────────────────────────────────
class _OrderSummaryCard extends StatefulWidget {
  final int orderNumber;
  final String customerName;
  final String dateTime;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onEdit;
  final bool updating;

  const _OrderSummaryCard({
    required this.orderNumber,
    required this.customerName,
    required this.dateTime,
    required this.statusLabel,
    required this.statusColor,
    this.onEdit,
    this.updating = false,
  });

  @override
  State<_OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<_OrderSummaryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 20,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${widget.orderNumber}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: _textMuted),
                            const SizedBox(width: 6),
                            Text(
                              widget.dateTime,
                              style: const TextStyle(fontSize: 13, color: _textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(label: widget.statusLabel, color: widget.statusColor),
                  if (widget.onEdit != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.updating ? null : widget.onEdit,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.edit_rounded, size: 20, color: _accent),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _textMuted.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
          ),
        ),
      ],
    );
  }
}

// ─── Item row card (thumbnail, name, qty, price, subtotal) ──────────────────
class _ItemCard extends StatefulWidget {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const _ItemCard({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final initial = widget.productName.isNotEmpty ? widget.productName[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 80),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 12,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accent.withValues(alpha: 0.25),
                        _accentDark.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _accentDark.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.quantity} × \$${widget.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, color: _textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${widget.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Total card ───────────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final double amount;

  const _TotalCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.15),
            _accentDark.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _accentDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment row with icon ─────────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  final String? paymentMethod;

  const _PaymentRow({this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    if (paymentMethod == null || paymentMethod!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.payment_rounded, size: 22, color: _textMuted),
            const SizedBox(width: 12),
            Text('Payment not set', style: TextStyle(fontSize: 14, color: _textMuted)),
          ],
        ),
      );
    }
    final icon = _paymentIcon(paymentMethod!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: _accent),
          ),
          const SizedBox(width: 14),
          Text(
            paymentMethod!,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'mobile':
        return Icons.phone_android_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}

// ─── Action buttons: Repeat, Refund, Print (+ Complete/Cancel if pending) ──
class _ActionButtons extends StatefulWidget {
  final Order order;
  final VoidCallback onRepeat;
  final VoidCallback onRefund;
  final VoidCallback onPrint;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final bool updating;

  const _ActionButtons({
    required this.order,
    required this.onRepeat,
    required this.onRefund,
    required this.onPrint,
    this.onComplete,
    this.onCancel,
    this.updating = false,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  int? _pressedIndex;

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool accent = false,
    bool destructive = false,
  }) {
    final index = label.hashCode;
    final isPressed = _pressedIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressedIndex = index),
          onPointerUp: (_) => setState(() => _pressedIndex = null),
          onPointerCancel: (_) => setState(() => _pressedIndex = null),
          child: AnimatedScale(
            scale: isPressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 80),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.updating ? null : onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: destructive
                        ? _errorColor.withValues(alpha: 0.08)
                        : accent
                            ? _accent
                            : _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: destructive
                          ? _errorColor.withValues(alpha: 0.3)
                          : accent
                              ? _accent
                              : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: [
                      if (!accent && !destructive)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: accent || destructive
                            ? (destructive ? _errorColor : Colors.white)
                            : _textPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent || destructive
                              ? (destructive ? _errorColor : Colors.white)
                              : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.order.status == 'pending';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildActionButton(icon: Icons.replay_rounded, label: 'Repeat', onTap: widget.onRepeat),
            _buildActionButton(icon: Icons.receipt_long_rounded, label: 'Refund', onTap: widget.onRefund),
            _buildActionButton(icon: Icons.print_rounded, label: 'Print', onTap: widget.onPrint),
          ],
        ),
        if (isPending) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cancel_rounded,
                  label: 'Cancel order',
                  onTap: widget.onCancel ?? () {},
                  destructive: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Complete',
                  onTap: widget.onComplete ?? () {},
                  accent: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
