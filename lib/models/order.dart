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
      productId: _toInt(json['productId'] ?? json['product_id']),
      productName: (json['productName'] ?? json['product_name']) as String? ?? '',
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unitPrice'] ?? json['unit_price']),
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discountAmount'] ?? json['discount_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
    'discountAmount': discountAmount,
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
    final userIdRaw = json['userId'] ?? json['user_id'];

    // paymentDetails may be a JSON object or string
    String? paymentDetails;
    final pd = json['paymentDetails'] ?? json['payment_details'];
    if (pd is String) {
      paymentDetails = pd;
    } else if (pd != null) {
      paymentDetails = pd.toString();
    }

    return Order(
      id: _toInt(json['id']),
      orderNumber: (json['orderNumber'] ?? json['order_number']) as String?,
      userId: userIdRaw == null ? null : _toInt(userIdRaw),
      cashierId: _toInt(json['cashierId'] ?? json['cashier_id']),
      subtotal: _toDouble(json['subtotal']),
      taxAmount: _toDouble(json['taxAmount'] ?? json['tax_amount']),
      discountAmount: _toDouble(json['discountAmount'] ?? json['discount_amount']),
      total: _toDouble(json['total']),
      status: (json['status'] as String?) ?? 'PENDING',
      paymentMethod: (json['paymentMethod'] ?? json['payment_method']) as String?,
      paymentDetails: paymentDetails,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
      items: itemsList != null
          ? itemsList.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'userId': userId,
    'cashierId': cashierId,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'total': total,
    'status': status,
    'paymentMethod': paymentMethod,
    'paymentDetails': paymentDetails,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'items': items.map((e) => e.toJson()).toList(),
  };
}
