import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Product should be created with valid data', () {
      final product = Product(
        id: 1,
        name: 'Coffee',
        sku: 'SKU-001',
        barcode: 'BAR-001',
        price: 3.50,
        cost: 1.50,
        stock: 100,
        categoryId: 1,
        imagePath: 'path',
        lowStockThreshold: 20,
        description: 'Hot coffee',
      );

      expect(product.id, 1);
      expect(product.name, 'Coffee');
      expect(product.price, 3.50);
      expect(product.stock, 100);
      expect(product.categoryId, 1);
      expect(product.lowStockThreshold, 20);
    });

    test('Product JSON serialization and deserialization', () {
      final json = {
        'id': 1,
        'name': 'Espresso',
        'sku': 'SKU-002',
        'barcode': 'BAR-002',
        'price': 2.50,
        'cost': 1.00,
        'stock': 50,
        'category_id': 1,
        'image_url': 'url',
        'low_stock_threshold': 10,
        'description': 'Strong coffee',
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Espresso');
      expect(product.price, 2.50);
      expect(product.stock, 50);
      expect(product.lowStockThreshold, 10);
    });

    test('Product should detect low stock', () {
      final product = Product(
        id: 1,
        name: 'Coffee',
        sku: 'SKU-001',
        barcode: 'BAR-001',
        price: 3.50,
        cost: 1.50,
        stock: 5,
        categoryId: 1,
        imagePath: 'path',
        lowStockThreshold: 20,
        description: 'Hot coffee',
      );

      expect(product.stock < product.lowStockThreshold, true);
    });

    test('Product should not be low stock when above threshold', () {
      final product = Product(
        id: 1,
        name: 'Coffee',
        sku: 'SKU-001',
        barcode: 'BAR-001',
        price: 3.50,
        cost: 1.50,
        stock: 50,
        categoryId: 1,
        imagePath: 'path',
        lowStockThreshold: 20,
        description: 'Hot coffee',
      );

      expect(product.stock >= product.lowStockThreshold, true);
    });

    test('Product profit calculation', () {
      final product = Product(
        id: 1,
        name: 'Coffee',
        sku: 'SKU-001',
        barcode: 'BAR-001',
        price: 3.50,
        cost: 1.50,
        stock: 100,
        categoryId: 1,
        imagePath: 'path',
        lowStockThreshold: 20,
        description: 'Hot coffee',
      );

      final profit = product.price - product.cost;
      expect(profit, 2.00);
    });
  });
}
