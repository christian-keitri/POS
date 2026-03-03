class Product {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final double cost;
  final int stock;
  final int? categoryId;
  final String? categoryName;

  const Product({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.cost = 0,
    this.stock = 0,
    this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: json['category_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'price': price,
        'cost': cost,
        'stock': stock,
        'category_id': categoryId,
      };
}
