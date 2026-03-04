/// Parses a JSON value that may be num or String to int/double.
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name'] as String? ?? '',
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      subtotal: _toDouble(json['subtotal']),
    );
  }
}

class Order {
  final int id;
  final int? userId;
  final int? cashierId;
  final double total;
  final String status;
  final String? paymentMethod;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    this.userId,
    this.cashierId,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    final userIdRaw = json['user_id'];
    return Order(
      id: _toInt(json['id']),
      userId: userIdRaw == null ? null : _toInt(userIdRaw),
      cashierId: (json['cashier_id'] as num?)?.toInt(),
      total: _toDouble(json['total']),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      items: itemsList != null
          ? itemsList.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}
