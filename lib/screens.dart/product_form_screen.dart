import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/models/category.dart';
import 'package:pos/models/product.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = create

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _stockController;
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _loading = false;
  bool _saving = false;
  bool _isActive = true;
  /// New image picked this session (camera or gallery)
  XFile? _pickedImage;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    _costController = TextEditingController(text: p != null ? p.cost.toString() : '0');
    _stockController = TextEditingController(text: p != null ? p.stock.toString() : '0');
    _selectedCategoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getCategories();
      if (mounted) setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final xFile = await _picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (xFile != null && mounted) setState(() => _pickedImage = xFile);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not pick image: $e');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim().isEmpty ? null : _skuController.text.trim();
    final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text);
    final cost = double.tryParse(_costController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    if (price == null || price < 0) {
      AppSnackBar.show(context, 'Enter a valid price');
      return;
    }
    setState(() => _saving = true);
    try {
      int productId;
      if (isEditing) {
        await ApiService.updateProduct(
          widget.product!.id,
          name: name,
          sku: sku,
          barcode: barcode,
          description: description,
          price: price,
          cost: cost,
          stock: stock,
          categoryId: _selectedCategoryId,
          isActive: _isActive,
        );
        productId = widget.product!.id;
        if (mounted) AppSnackBar.success(context, 'Product updated');
      } else {
        final created = await ApiService.createProduct(
          name: name,
          sku: sku,
          barcode: barcode,
          description: description,
          price: price,
          cost: cost,
          stock: stock,
          categoryId: _selectedCategoryId,
          isActive: _isActive,
        );
        productId = created.id;
        if (mounted) AppSnackBar.success(context, 'Product created');
      }
      if (_pickedImage != null) {
        final file = File(_pickedImage!.path);
        if (file.existsSync()) {
          await ApiService.uploadProductImage(productId, file);
          if (mounted) AppSnackBar.success(context, 'Image uploaded');
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildImageSection() {
    final existingPath = widget.product?.imagePath;
    final hasExisting = existingPath != null && existingPath.isNotEmpty;
    final hasNew = _pickedImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product image', style: AppTheme.captionStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 100,
                child: hasNew
                    ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                    : hasExisting
                        ? Image.network(
                            productImageUrl(existingPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.border,
                              child: const Icon(Icons.broken_image_outlined, size: 40),
                            ),
                          )
                        : Container(
                            color: AppTheme.border,
                            child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppTheme.textMuted),
                          ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: _saving ? null : () => _pickImage(false),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: const Text('Gallery'),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : () => _pickImage(true),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('Camera'),
                ),
                if (hasNew)
                  TextButton.icon(
                    onPressed: _saving ? null : () => setState(() => _pickedImage = null),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppTheme.appBarBackground,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                        hintText: 'e.g. Espresso',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU',
                              hintText: 'Optional',
                              prefixIcon: Icon(Icons.qr_code_2_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Barcode',
                              hintText: 'Optional',
                              prefixIcon: Icon(Icons.barcode_reader),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(labelText: 'Cost'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(labelText: 'Stock'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Short product description',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: AppTheme.surfaceElevated,
                      child: SwitchListTile(
                        title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          _isActive ? 'Product is visible and sellable' : 'Hidden from POS',
                          style: AppTheme.captionStyle,
                        ),
                        value: _isActive,
                        onChanged: _saving ? null : (v) => setState(() => _isActive = v),
                        activeColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
