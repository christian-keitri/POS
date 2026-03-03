import 'package:flutter/material.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/core/app_state.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Product> _products = [];
  final Map<int, int> _cart = {}; // productId -> quantity
  bool _loading = true;
  bool _placing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getProducts();
      if (mounted) setState(() {
        _products = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _addToCart(Product p, [int qty = 1]) {
    setState(() {
      _cart[p.id] = (_cart[p.id] ?? 0) + qty;
    });
  }

  void _removeFromCart(int productId, [int qty = 1]) {
    setState(() {
      final current = _cart[productId] ?? 0;
      if (current <= qty) {
        _cart.remove(productId);
      } else {
        _cart[productId] = current - qty;
      }
    });
  }

  double get _cartTotal {
    double t = 0;
    for (final e in _cart.entries) {
      final idx = _products.indexWhere((x) => x.id == e.key);
      if (idx >= 0) t += _products[idx].price * e.value;
    }
    return t;
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      final items = _cart.entries
          .map((e) => {'product_id': e.key, 'quantity': e.value})
          .toList();
      await ApiService.createOrder(
        userId: AppState.currentUser?.id,
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $msg')),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
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
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, i) {
                          final p = _products[i];
                          final qty = _cart[p.id] ?? 0;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _addToCart(p),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (p.imagePath != null && p.imagePath!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          productImageUrl(p.imagePath),
                                          height: 56,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppTheme.border,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.inventory_2_rounded, color: AppTheme.textMuted, size: 32),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p.name,
                                      style: AppTheme.headingStyle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${p.price.toStringAsFixed(2)}',
                                          style: AppTheme.titleStyle.copyWith(color: AppTheme.primary),
                                        ),
                                        if (qty > 0)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton.filled(
                                                style: IconButton.styleFrom(
                                                  padding: const EdgeInsets.all(4),
                                                  minimumSize: const Size(32, 32),
                                                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                                                ),
                                                onPressed: () => _removeFromCart(p.id),
                                                icon: const Icon(Icons.remove, size: 18),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('$qty', style: AppTheme.headingStyle),
                                              ),
                                              IconButton.filled(
                                                style: IconButton.styleFrom(
                                                  padding: const EdgeInsets.all(4),
                                                  minimumSize: const Size(32, 32),
                                                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                                                ),
                                                onPressed: () => _addToCart(p),
                                                icon: const Icon(Icons.add, size: 18),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_cartItemCount} items', style: AppTheme.captionStyle),
                                  Text(
                                    '\$${_cartTotal.toStringAsFixed(2)}',
                                    style: AppTheme.titleStyle,
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _cart.isEmpty || _placing ? null : _placeOrder,
                              icon: _placing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(_placing ? 'Placing…' : 'Place Order'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
