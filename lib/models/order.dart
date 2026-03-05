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
  final double discountAmount;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.discountAmount = 0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      productName: json['product_name'] as String? ?? '',
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discount_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'subtotal': subtotal,
    'discount_amount': discountAmount,
  };
}

class Order {
  final int id;
  final String? orderNumber;
  final int? userId;
  final int? cashierId;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String status;
  final String? paymentMethod;
  final String? paymentDetails;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    this.orderNumber,
    this.userId,
    this.cashierId,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.paymentDetails,
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
      orderNumber: json['order_number'] as String?,
      userId: userIdRaw == null ? null : _toInt(userIdRaw),
      cashierId: (json['cashier_id'] as num?)?.toInt(),
      subtotal: _toDouble(json['subtotal']),
      taxAmount: _toDouble(json['tax_amount']),
      discountAmount: _toDouble(json['discount_amount']),
      total: _toDouble(json['total']),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      paymentDetails: json['payment_details'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      items: itemsList != null
          ? itemsList.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'user_id': userId,
    'cashier_id': cashierId,
    'subtotal': subtotal,
    'tax_amount': taxAmount,
    'discount_amount': discountAmount,
    'total': total,
    'status': status,
    'payment_method': paymentMethod,
    'payment_details': paymentDetails,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'items': items.map((e) => e.toJson()).toList(),
  };
}
