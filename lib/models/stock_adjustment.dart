class StockAdjustment {
  final int id;
  final int productId;
  final String? productName;
  final String? productSku;
  final int? userId;
  final String? userEmail;
  final int quantityChange;
  final int oldStock;
  final int newStock;
  final String reason;
  final String? notes;
  final String? referenceType;
  final int? referenceId;
  final String createdAt;

  const StockAdjustment({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    this.userId,
    this.userEmail,
    required this.quantityChange,
    required this.oldStock,
    required this.newStock,
    required this.reason,
    this.notes,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      productName: json['product_name'] as String?,
      productSku: json['product_sku'] as String?,
      userId: (json['user_id'] as num?)?.toInt(),
      userEmail: json['user_email'] as String?,
      quantityChange: (json['quantity_change'] as num).toInt(),
      oldStock: (json['old_stock'] as num).toInt(),
      newStock: (json['new_stock'] as num).toInt(),
      reason: json['reason'] as String,
      notes: json['notes'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: (json['reference_id'] as num?)?.toInt(),
      createdAt: json['created_at'] as String,
    );
  }

  String get reasonDisplay {
    switch (reason) {
      case 'sale':
        return 'Sale';
      case 'purchase':
        return 'Purchase';
      case 'adjustment':
        return 'Manual Adjustment';
      case 'damage':
        return 'Damaged/Lost';
      case 'return':
        return 'Customer Return';
      default:
        return reason;
    }
  }
}
