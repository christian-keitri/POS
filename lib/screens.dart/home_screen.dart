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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  const _DashboardTab({required this.onNewOrder});

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
      if (mounted) setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
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
      );
    }
    final count = (_stats?['today_orders_count'] as num?)?.toInt() ?? 0;
    final revenue = (_stats?['today_revenue'] as num?)?.toDouble() ?? 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Dashboard', style: AppTheme.titleStyle),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_rounded,
                  label: "Today's Orders",
                  value: '$count',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money_rounded,
                  label: "Today's Revenue",
                  value: '\$${revenue.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: widget.onNewOrder,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('New Order'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 12),
            Text(label, style: AppTheme.captionStyle),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.titleStyle),
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
      final list = await ApiService.getOrders(userId: AppState.currentUser?.id);
      if (mounted) setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text('No orders yet', style: AppTheme.bodySecondaryStyle),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: widget.onNewOrder,
                            icon: const Icon(Icons.add),
                            label: const Text('Create first order'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('Order #${o.id}', style: AppTheme.bodyStyle),
                              subtitle: Text(
                                '\$${o.total.toStringAsFixed(2)} · ${o.status}',
                                style: AppTheme.captionStyle,
                              ),
                              trailing: const Icon(Icons.chevron_right),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_fab',
        onPressed: widget.onNewOrder,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
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
        ApiService.getProducts(categoryId: _filterCategoryId),
        ApiService.getCategories(),
      ]);
      if (mounted) setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
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
      onBackgroundImageError: (_, __) {},
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: DropdownButtonFormField<int?>(
                        value: _filterCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ..._categories.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (v) => setState(() {
                          _filterCategoryId = v;
                          _load();
                        }),
                      ),
                    ),
                    Expanded(
                      child: _products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_rounded, size: 64, color: AppTheme.textMuted),
                                  const SizedBox(height: 16),
                                  Text('No products', style: AppTheme.bodySecondaryStyle),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _products.length,
                              itemBuilder: (context, i) {
                                final p = _products[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: _productThumbnail(p.imagePath),
                                    title: Text(p.name, style: AppTheme.bodyStyle),
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
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
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
      if (mounted) setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, true),
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
    try {
      await ApiService.createCategory(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profile', style: AppTheme.titleStyle),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.email ?? '—', style: AppTheme.bodyStyle),
                  if (user?.businessName != null) ...[
                    const SizedBox(height: 4),
                    Text(user!.businessName!, style: AppTheme.captionStyle),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories', style: AppTheme.headingStyle),
              TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
            else
              ..._categories.map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(c.name, style: AppTheme.bodyStyle),
                    ),
                  )),
        ],
      ),
    );
  }
}
