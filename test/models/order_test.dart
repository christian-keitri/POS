import 'package:flutter_test/flutter_test.dart';
import 'package:pos/models/order.dart';

void main() {
  group('Order Model Tests', () {
    test('Order should be created with valid data', () {
      final order = Order(
        id: 1,
        userId: 1,
        status: 'completed',
        total: 100.0,
        taxAmount: 10.0,
        discountAmount: 5.0,
        paymentMethod: 'cash',
        notes: 'Test order',
        createdAt: '2024-03-23T00:00:00Z',
      );

      expect(order.id, 1);
      expect(order.userId, 1);
      expect(order.status, 'completed');
      expect(order.total, 100.0);
      expect(order.taxAmount, 10.0);
      expect(order.discountAmount, 5.0);
      expect(order.paymentMethod, 'cash');
    });

    test('Order JSON serialization and deserialization', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'status': 'pending',
        'total': 150.0,
        'tax_amount': 15.0,
        'discount_amount': 10.0,
        'payment_method': 'card',
        'notes': 'VIP order',
        'created_at': '2024-03-23T10:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, 1);
      expect(order.userId, 1);
      expect(order.status, 'pending');
      expect(order.total, 150.0);
      expect(order.taxAmount, 15.0);
      expect(order.paymentMethod, 'card');
    });

    test('Order should identify completed status', () {
      final order = Order(
        id: 1,
        userId: 1,
        status: 'completed',
        total: 100.0,
        taxAmount: 10.0,
        discountAmount: 5.0,
        paymentMethod: 'cash',
        notes: 'Test',
        createdAt: '2024-03-23T00:00:00Z',
      );

      expect(order.status, 'completed');
    });

    test('Order should calculate subtotal correctly', () {
      final order = Order(
        id: 1,
        userId: 1,
        status: 'completed',
        total: 100.0,
        subtotal: 95.0,
        taxAmount: 10.0,
        discountAmount: 5.0,
        paymentMethod: 'cash',
        notes: 'Test',
        createdAt: '2024-03-23T00:00:00Z',
      );

      expect(order.subtotal, 95.0);
    });
  });
}
