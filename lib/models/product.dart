class Product {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? description;
  final double price;
  final double cost;
  final int stock;
  final int lowStockThreshold;
  final int? categoryId;
  final String? categoryName;
  /// Server path (filename) for product image; full URL is apiBaseUrl + /uploads/ + imagePath
  final String? imagePath;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.description,
    required this.price,
    this.cost = 0,
    this.stock = 0,
    this.lowStockThreshold = 10,
    this.categoryId,
    this.categoryName,
    this.imagePath,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final isActiveRaw = json['is_active'];
    final isActive = isActiveRaw == null ? true : (isActiveRaw == 1 || isActiveRaw == true);
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 10,
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: json['category_name'] as String?,
      imagePath: json['image_path'] as String?,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'description': description,
        'price': price,
        'cost': cost,
        'stock': stock,
        'category_id': categoryId,
        'is_active': isActive ? 1 : 0,
      };
}
