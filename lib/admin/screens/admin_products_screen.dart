import 'package:flutter/material.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/category.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/screens/product_form_screen.dart';

/// Product & inventory management: list, search, filter, sort, CRUD, low-stock, import/export placeholders.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  int? _categoryFilterId;
  String _sortBy = 'name'; // name, price, stock
  bool _sortAsc = true;
  bool _lowStockOnly = false;

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
        ApiService.getProducts(categoryId: _categoryFilterId, activeOnly: false),
        ApiService.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
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

  List<Product> get _filteredProducts {
    var list = _products;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.barcode?.contains(q) ?? false);
      }).toList();
    }
    if (_lowStockOnly) {
      list = list.where((p) => p.stock <= p.lowStockThreshold).toList();
    }
    list = List.from(list)
      ..sort((a, b) {
        int cmp;
        switch (_sortBy) {
          case 'price':
            cmp = a.price.compareTo(b.price);
            break;
          case 'stock':
            cmp = a.stock.compareTo(b.stock);
            break;
          default:
            cmp = a.name.compareTo(b.name);
        }
        return _sortAsc ? cmp : -cmp;
      });
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
                'Products & Inventory',
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
                  SizedBox(
                    width: 220,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        hintText: 'Name, SKU, barcode',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  DropdownButton<int?>(
                    value: _categoryFilterId,
                    hint: const Text('All categories'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                      ..._categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _categoryFilterId = v);
                      _load();
                    },
                  ),
                  DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Sort by name')),
                      DropdownMenuItem(value: 'price', child: Text('Sort by price')),
                      DropdownMenuItem(value: 'stock', child: Text('Sort by stock')),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v ?? _sortBy),
                  ),
                  IconButton(
                    icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () => setState(() => _sortAsc = !_sortAsc),
                    tooltip: _sortAsc ? 'Ascending' : 'Descending',
                  ),
                  FilterChip(
                    label: const Text('Low stock only'),
                    selected: _lowStockOnly,
                    onSelected: (v) => setState(() => _lowStockOnly = v),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openProductForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add product'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importPlaceholder,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Import'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportPlaceholder,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export'),
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
                  : _ProductsTable(
                      products: _filteredProducts,
                      onEdit: _editProduct,
                      onDelete: _deleteProduct,
                      onRefresh: _load,
                    ),
        ),
      ],
    );
  }

  void _openProductForm(BuildContext context, [Product? product]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _editProduct(Product p) => _openProductForm(context, p);

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Remove "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _importPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk import: connect your CSV/API endpoint here')),
    );
  }

  void _exportPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export: generate CSV/PDF from current product list (placeholder)')),
    );
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

class _ProductsTable extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;
  final VoidCallback onRefresh;

  const _ProductsTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 800;
    if (isNarrow) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];
            final lowStock = p.stock <= p.lowStockThreshold;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: p.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          productImageUrl(p.imagePath),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_rounded),
                        ),
                      )
                    : const Icon(Icons.inventory_2_rounded),
                title: Text(p.name),
                subtitle: Text('${p.categoryName ?? '—'} · \$${p.price.toStringAsFixed(2)} · Stock: ${p.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lowStock)
                      Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                    IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => onEdit(p)),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: AppTheme.error),
                      onPressed: () => onDelete(p),
                    ),
                  ],
                ),
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
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Price'), numeric: true),
            DataColumn(label: Text('Stock'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions'), numeric: true),
          ],
          rows: products.map((p) {
            final lowStock = p.stock <= p.lowStockThreshold;
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    if (p.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            productImageUrl(p.imagePath),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_rounded),
                          ),
                        ),
                      ),
                    Text(p.name),
                  ],
                )),
                DataCell(Text(p.categoryName ?? '—')),
                DataCell(Text('\$${p.price.toStringAsFixed(2)}')),
                DataCell(Row(
                  children: [
                    Text('${p.stock}'),
                    if (lowStock) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.error),
                    ],
                  ],
                )),
                DataCell(Chip(
                  label: Text(p.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: p.isActive ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.textMuted.withValues(alpha: 0.3),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => onEdit(p)),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: AppTheme.error),
                      onPressed: () => onDelete(p),
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
}
