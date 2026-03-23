import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/category.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/user.dart';

void main() {
  group('API Service Parsing Tests', () {
    test('Parse product list from JSON', () {
      final jsonList = [
        {
          'id': 1,
          'name': 'Coffee',
          'sku': 'SKU-001',
          'barcode': 'BAR-001',
          'price': 3.50,
          'cost': 1.50,
          'stock': 100,
          'category_id': 1,
          'image_path': 'url',
          'low_stock_threshold': 20,
          'description': 'Hot coffee',
        },
        {
          'id': 2,
          'name': 'Tea',
          'sku': 'SKU-002',
          'barcode': 'BAR-002',
          'price': 2.50,
          'cost': 1.00,
          'stock': 150,
          'category_id': 1,
          'image_path': 'url',
          'low_stock_threshold': 30,
          'description': 'Hot tea',
        },
      ];

      final products = jsonList.map((json) => Product.fromJson(json)).toList();

      expect(products.length, 2);
      expect(products[0].name, 'Coffee');
      expect(products[1].name, 'Tea');
    });

    test('Parse category list from JSON', () {
      final jsonList = [
        {
          'id': 1,
          'name': 'Beverages',
          'description': 'All beverages',
        },
        {
          'id': 2,
          'name': 'Food',
          'description': 'All food items',
        },
      ];

      final categories =
          jsonList.map((json) => Category.fromJson(json)).toList();

      expect(categories.length, 2);
      expect(categories[0].name, 'Beverages');
      expect(categories[1].name, 'Food');
    });

    test('Parse user from JSON', () {
      final json = {
        'id': 1,
        'email': 'user@example.com',
        'display_name': 'John Doe',
        'business_name': 'My Store',
        'role': 'cashier',
        'created_at': '2024-03-23T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.email, 'user@example.com');
      expect(user.displayName, 'John Doe');
      expect(user.role, 'cashier');
    });

    test('Handle null values in JSON parsing', () {
      final json = {
        'id': 1,
        'name': 'Product',
        'sku': 'SKU-001',
        'barcode': 'BAR-001',
        'price': 10.0,
        'cost': 5.0,
        'stock': 50,
        'category_id': 1,
        'image_path': null,
        'low_stock_threshold': 10,
        'description': null,
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Product');
      expect(product.imagePath, null);
      expect(product.description, null);
    });
  });
}
