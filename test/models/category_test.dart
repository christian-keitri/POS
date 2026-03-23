import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/category.dart';

void main() {
  group('Category Model Tests', () {
    test('Category should be created with valid data', () {
      final category = Category(
        id: 1,
        name: 'Beverages',
        description: 'All beverages',
      );

      expect(category.id, 1);
      expect(category.name, 'Beverages');
      expect(category.description, 'All beverages');
    });

    test('Category JSON serialization and deserialization', () {
      final json = {
        'id': 2,
        'name': 'Food',
        'description': 'All food items',
      };

      final category = Category.fromJson(json);

      expect(category.id, 2);
      expect(category.name, 'Food');
      expect(category.description, 'All food items');
    });

    test('Category to JSON conversion', () {
      final category = Category(
        id: 1,
        name: 'Beverages',
        description: 'All beverages',
      );

      final json = category.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Beverages');
      expect(json['description'], 'All beverages');
    });
  });
}
