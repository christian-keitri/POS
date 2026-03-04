import 'package:flutter/material.dart';
import 'package:pos/Core/custom_app_bar.dart';
import 'package:pos/Core/custom_bottom_nav.dart';
import 'package:pos/core/app_state.dart';
import 'package:pos/models/category.dart';
import 'package:pos/models/order.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/screens.dart/cart_screen.dart';
import 'package:pos/screens.dart/order_detail_screen.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/screens.dart/product_form_screen.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/widgets/category_pills.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;
  final String title;

  const HomeScreen({super.key, this.userName, this.title = 'POS'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _refreshOrders = 0;
  int _refreshProducts = 0;

  final List<NavItem> navItems = [
    NavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
    NavItem(icon: Icons.shopping_cart_rounded, label: 'Orders', index: 1),
    NavItem(icon: Icons.inventory_2_rounded, label: 'Products', index: 2),
    NavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
  ];

  void _goToOrdersTab() => setState(() => _currentIndex = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: CustomAppBar.build(context, widget.userName),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            onNewOrder: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
              if (result == true && mounted) {
                setState(() {
                  _refreshOrders++;
                  _refreshProducts++;
                });
              }
            },
            onViewOrders: _goToOrdersTab,
          ),
          _OrdersTab(
            refreshTrigger: _refreshOrders,
            onNewOrder: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
              if (result == true && mounted) setState(() => _refreshOrders++);
            },
          ),
          _ProductsTab(
            refreshTrigger: _refreshProducts,
            onProductSaved: () => setState(() => _refreshProducts++),
          ),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: navItems,
        activeColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final VoidCallback onNewOrder;
  final VoidCallback? onViewOrders;

  const _DashboardTab({required this.onNewOrder, this.onViewOrders});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _stats;
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
      final stats = await ApiService.getOrderStats(userId: AppState.currentUser?.id);
      if (mounted) {
        setState(() {
        _stats = stats;
        _loading = false;
      });
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text('Loading dashboard…', style: AppTheme.bodySecondaryStyle),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 20),
              Text(
                'Couldn’t load stats',
                style: AppTheme.headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!.replaceFirst('Exception: ', ''),
                style: AppTheme.bodySecondaryStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final count = (_stats?['today_orders_count'] as num?)?.toInt() ?? 0;
    final revenue = (_stats?['today_revenue'] as num?)?.toDouble() ?? 0.0;
    final dateStr = _formatDate(DateTime.now());
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_greeting(), style: AppTheme.captionStyle),
            const SizedBox(height: 4),
            Text('Dashboard', style: AppTheme.titleStyle.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(dateStr, style: AppTheme.bodySecondaryStyle.copyWith(fontSize: 13)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: "Today's orders",
                    value: '$count',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    icon: Icons.attach_money_rounded,
                    label: "Today's revenue",
                    value: '\$${revenue.toStringAsFixed(2)}',
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onNewOrder,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New order', style: AppTheme.headingStyle),
                              const SizedBox(height: 2),
                              Text('Start a new sale', style: AppTheme.captionStyle),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.onViewOrders != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: widget.onViewOrders,
                icon: const Icon(Icons.receipt_long_outlined, size: 20),
                label: const Text('View all orders'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(label, style: AppTheme.captionStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.titleStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  final int refreshTrigger;
  final VoidCallback onNewOrder;

  const _OrdersTab({required this.refreshTrigger, required this.onNewOrder});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _OrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getOrders(userId: AppState.currentUser?.id, status: _statusFilter);
      if (mounted) {
        setState(() {
        _orders = list;
        _loading = false;
      });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text('Loading orders…', style: AppTheme.bodySecondaryStyle),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 20),
                        Text('Couldn’t load orders', style: AppTheme.headingStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(_error!.replaceFirst('Exception: ', ''), style: AppTheme.bodySecondaryStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.receipt_long_rounded, size: 56, color: AppTheme.primary.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 24),
                            Text('No orders yet', style: AppTheme.headingStyle, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first order to see it here.',
                              style: AppTheme.bodySecondaryStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            FilledButton.icon(
                              onPressed: widget.onNewOrder,
                              icon: const Icon(Icons.add_shopping_cart_rounded),
                              label: const Text('New order'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              Text('Orders', style: AppTheme.titleStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${_orders.length}', style: AppTheme.smallStyle.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _FilterChip(label: 'All', selected: _statusFilter == null, onTap: () => setState(() { _statusFilter = null; _load(); })),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Pending', selected: _statusFilter == 'pending', onTap: () => setState(() { _statusFilter = 'pending'; _load(); })),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Completed', selected: _statusFilter == 'completed', onTap: () => setState(() { _statusFilter = 'completed'; _load(); })),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Cancelled', selected: _statusFilter == 'cancelled', onTap: () => setState(() { _statusFilter = 'cancelled'; _load(); })),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _orders.length,
                              itemBuilder: (context, i) {
                                final o = _orders[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 0,
                                  color: AppTheme.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: o.status == 'completed'
                                          ? AppTheme.success.withValues(alpha: 0.15)
                                          : o.status == 'cancelled'
                                              ? AppTheme.error.withValues(alpha: 0.15)
                                              : AppTheme.primary.withValues(alpha: 0.15),
                                      child: Icon(
                                        o.status == 'completed' ? Icons.check_rounded : o.status == 'cancelled' ? Icons.close_rounded : Icons.receipt_long_rounded,
                                        color: o.status == 'completed' ? AppTheme.success : o.status == 'cancelled' ? AppTheme.error : AppTheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text('Order #${o.id}', style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '\$${o.total.toStringAsFixed(2)} · ${o.status}${o.paymentMethod != null ? ' · ${o.paymentMethod}' : ''}',
                                      style: AppTheme.captionStyle,
                                    ),
                                    trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailScreen(orderId: o.id),
                                      ),
                                    ).then((_) => _load()),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_fab',
        onPressed: widget.onNewOrder,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New order'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final int refreshTrigger;
  final VoidCallback? onProductSaved;

  const _ProductsTab({required this.refreshTrigger, this.onProductSaved});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<Product> _products = [];
  List<Category> _categories = [];
  int? _filterCategoryId;
  bool _showInactive = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ProductsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getProducts(categoryId: _filterCategoryId, activeOnly: !_showInactive),
        ApiService.getCategories(),
      ]);
      if (mounted) {
        setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
        _loading = false;
      });
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

  Widget _productThumbnail(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.border,
        child: Icon(Icons.inventory_2_rounded, color: AppTheme.textMuted, size: 28),
      );
    }
    final url = productImageUrl(imagePath);
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.border,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, _) {},
      child: url.isEmpty ? const Icon(Icons.broken_image) : null,
    );
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.deleteProduct(p.id);
      if (mounted) {
        AppSnackBar.success(context, 'Product deleted');
        _load();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        AppSnackBar.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text('Loading products…', style: AppTheme.bodySecondaryStyle),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 20),
                        Text('Couldn’t load products', style: AppTheme.headingStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(_error!.replaceFirst('Exception: ', ''), style: AppTheme.bodySecondaryStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Text('Products', style: AppTheme.titleStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${_products.length}', style: AppTheme.smallStyle.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    CategoryPills(
                      categories: _categories,
                      selectedCategoryId: _filterCategoryId,
                      onCategorySelected: (id) {
                        setState(() {
                          _filterCategoryId = id;
                          _load();
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text('Show inactive', style: AppTheme.captionStyle),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showInactive,
                            onChanged: (v) => setState(() {
                              _showInactive = v;
                              _load();
                            }),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _products.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.inventory_2_rounded, size: 56, color: AppTheme.primary.withValues(alpha: 0.8)),
                                    ),
                                    const SizedBox(height: 24),
                                    Text('No products', style: AppTheme.headingStyle, textAlign: TextAlign.center),
                                    const SizedBox(height: 8),
                                    Text(
                                      _filterCategoryId != null
                                          ? 'No products in this category.'
                                          : 'Add your first product to get started.',
                                      style: AppTheme.bodySecondaryStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 28),
                                    FilledButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                                      ).then((_) {
                                        widget.onProductSaved?.call();
                                        _load();
                                      }),
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add product'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _products.length,
                              itemBuilder: (context, i) {
                                final p = _products[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 0,
                                  color: AppTheme.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: _productThumbnail(p.imagePath),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(p.name, style: AppTheme.bodyStyle),
                                        ),
                                        if (!p.isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.textMuted.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Inactive',
                                              style: AppTheme.smallStyle.copyWith(color: AppTheme.textSecondary),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '\$${p.price.toStringAsFixed(2)} · Stock: ${p.stock}',
                                      style: AppTheme.captionStyle,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductFormScreen(product: p),
                                            ),
                                          ).then((_) {
                                            widget.onProductSaved?.call();
                                            _load();
                                          });
                                        } else if (v == 'delete') {
                                          _deleteProduct(p);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductFormScreen(product: p),
                                      ),
                                    ).then((_) {
                                      widget.onProductSaved?.call();
                                      _load();
                                    }),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ).then((_) {
          widget.onProductSaved?.call();
          _load();
        }),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  List<Category> _categories = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getCategories();
      if (mounted) {
        setState(() {
        _categories = list;
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final sortController = TextEditingController(text: '0');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Beverages',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                autofocus: true,
                onSubmitted: (_) => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sortController,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  hintText: '0 = first',
                  prefixIcon: Icon(Icons.sort_rounded),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final sortOrder = int.tryParse(sortController.text.trim()) ?? 0;
    try {
      await ApiService.createCategory(name, description: descController.text.trim().isEmpty ? null : descController.text.trim(), sortOrder: sortOrder);
      if (mounted) {
        AppSnackBar.success(context, 'Category added');
        _load();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed: $e');
    }
  }

  Future<void> _editCategory(Category c) async {
    final nameController = TextEditingController(text: c.name);
    final descController = TextEditingController(text: c.description ?? '');
    final sortController = TextEditingController(text: '${c.sortOrder}');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.category_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sortController,
                decoration: const InputDecoration(labelText: 'Sort order', prefixIcon: Icon(Icons.sort_rounded)),
                keyboardType: TextInputType.number,
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
      ),
    );
    if (result != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final sortOrder = int.tryParse(sortController.text.trim()) ?? 0;
    try {
      await ApiService.updateCategory(c.id, name, description: descController.text.trim().isEmpty ? null : descController.text.trim(), sortOrder: sortOrder);
      if (mounted) {
        AppSnackBar.success(context, 'Category updated');
        _load();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed: $e');
    }
  }

  Future<void> _deleteCategory(Category c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Remove "${c.name}"? Products in this category will keep the category link until you change them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.deleteCategory(c.id);
      if (mounted) {
        AppSnackBar.success(context, 'Category deleted');
        _load();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        AppSnackBar.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.currentUser;
    return Container(
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Profile', style: AppTheme.titleStyle.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Account & settings', style: AppTheme.bodySecondaryStyle),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        (user?.displayName ?? '?').isNotEmpty ? (user!.displayName[0].toUpperCase()) : '?',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? 'Guest', style: AppTheme.headingStyle),
                          const SizedBox(height: 2),
                          Text(user?.email ?? '—', style: AppTheme.captionStyle),
                          if (user?.businessName != null && user!.businessName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(user.businessName!, style: AppTheme.smallStyle),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categories', style: AppTheme.headingStyle),
                    const SizedBox(height: 2),
                    Text('Manage product categories', style: AppTheme.captionStyle.copyWith(fontSize: 12)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
            else
              ..._categories.map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text('${c.sortOrder}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                      title: Text(c.name, style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500)),
                      subtitle: c.description != null && c.description!.isNotEmpty
                          ? Text(c.description!, style: AppTheme.captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 22),
                        onSelected: (value) {
                          if (value == 'edit') _editCategory(c);
                          if (value == 'delete') _deleteCategory(c);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 22), SizedBox(width: 12), Text('Edit')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 22, color: AppTheme.error), SizedBox(width: 12), Text('Delete', style: TextStyle(color: AppTheme.error))])),
                        ],
                      ),
                      onTap: () => _editCategory(c),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
