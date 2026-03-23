import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('User should be created with valid data', () {
      final user = User(
        id: 1,
        email: 'user@example.com',
        displayName: 'John Doe',
        businessName: 'My Store',
        role: 'cashier',
        createdAt: '2024-03-23T00:00:00Z',
      );

      expect(user.id, 1);
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'John Doe');
      expect(user.businessName, 'My Store');
      expect(user.role, 'cashier');
    });

    test('User JSON serialization and deserialization', () {
      final json = {
        'id': 1,
        'email': 'admin@example.com',
        'display_name': 'Admin User',
        'business_name': 'Admin Business',
        'role': 'admin',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.email, 'admin@example.com');
      expect(user.displayName, 'Admin User');
      expect(user.businessName, 'Admin Business');
      expect(user.role, 'admin');
    });

    test('User should identify admin role correctly', () {
      final adminUser = User(
        id: 1,
        email: 'admin@example.com',
        displayName: 'Admin',
        businessName: 'Store',
        role: 'admin',
        createdAt: '2024-03-23T00:00:00Z',
      );

      expect(adminUser.isAdmin, true);
    });

    test('User should identify non-admin role correctly', () {
      final regularUser = User(
        id: 1,
        email: 'user@example.com',
        displayName: 'User',
        businessName: 'Store',
        role: 'cashier',
        createdAt: '2024-03-23T00:00:00Z',
      );

      expect(regularUser.isAdmin, false);
    });

    test('User to JSON conversion', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        displayName: 'Test User',
        businessName: 'Test Business',
        role: 'cashier',
        createdAt: '2024-03-23T00:00:00Z',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['email'], 'test@example.com');
      expect(json['display_name'], 'Test User');
      expect(json['business_name'], 'Test Business');
      expect(json['role'], 'cashier');
    });
  });
}
