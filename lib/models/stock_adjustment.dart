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
    // Handle nested product/user objects from Prisma include
    final product = json['product'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;

    return StockAdjustment(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num?)?.toInt()
          ?? (json['product_id'] as num?)?.toInt()
          ?? (product?['id'] as num?)?.toInt()
          ?? 0,
      productName: json['productName'] as String?
          ?? json['product_name'] as String?
          ?? product?['name'] as String?,
      productSku: json['productSku'] as String?
          ?? json['product_sku'] as String?
          ?? product?['sku'] as String?,
      userId: (json['userId'] as num?)?.toInt()
          ?? (json['user_id'] as num?)?.toInt()
          ?? (user?['id'] as num?)?.toInt(),
      userEmail: json['userEmail'] as String?
          ?? json['user_email'] as String?
          ?? user?['email'] as String?,
      quantityChange: (json['quantityChange'] as num?)?.toInt()
          ?? (json['quantity_change'] as num?)?.toInt()
          ?? 0,
      oldStock: (json['oldStock'] as num?)?.toInt()
          ?? (json['old_stock'] as num?)?.toInt()
          ?? 0,
      newStock: (json['newStock'] as num?)?.toInt()
          ?? (json['new_stock'] as num?)?.toInt()
          ?? 0,
      reason: json['reason'] as String,
      notes: json['notes'] as String?,
      referenceType: (json['referenceType'] ?? json['reference_type']) as String?,
      referenceId: (json['referenceId'] as num?)?.toInt()
          ?? (json['reference_id'] as num?)?.toInt(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
    );
  }

  String get reasonDisplay {
    switch (reason.toUpperCase()) {
      case 'SALE':
        return 'Sale';
      case 'PURCHASE':
        return 'Purchase';
      case 'ADJUSTMENT':
        return 'Manual Adjustment';
      case 'DAMAGE':
        return 'Damaged/Lost';
      case 'RETURN':
        return 'Customer Return';
      default:
        return reason;
    }
  }
}
