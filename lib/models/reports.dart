class SalesReport {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final double totalTax;
  final double totalDiscounts;
  final List<PaymentMethodSummary> paymentMethods;

  const SalesReport({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalTax,
    required this.totalDiscounts,
    this.paymentMethods = const [],
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    // Backend returns paymentBreakdown (camelCase)
    final paymentList = (json['paymentBreakdown'] ?? json['payment_methods']) as List<dynamic>?;

    return SalesReport(
      totalOrders: (summary['totalOrders'] ?? summary['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (summary['totalRevenue'] ?? summary['total_revenue'] as num?)?.toDouble() ?? 0,
      averageOrderValue: (summary['avgOrderValue'] ?? summary['average_order_value'] as num?)?.toDouble() ?? 0,
      totalTax: (summary['totalTax'] ?? summary['total_tax'] as num?)?.toDouble() ?? 0,
      totalDiscounts: (summary['totalDiscounts'] ?? summary['total_discounts'] as num?)?.toDouble() ?? 0,
      paymentMethods: paymentList?.map((e) => PaymentMethodSummary.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class PaymentMethodSummary {
  final String? paymentMethod;
  final int count;
  final double total;

  const PaymentMethodSummary({
    this.paymentMethod,
    required this.count,
    required this.total,
  });

  factory PaymentMethodSummary.fromJson(Map<String, dynamic> json) {
    return PaymentMethodSummary(
      // Backend returns 'method' key from paymentBreakdown
      paymentMethod: (json['method'] ?? json['paymentMethod'] ?? json['payment_method']) as String?,
      count: (json['count'] as num?)?.toInt() ?? (json['_count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  String get methodDisplay {
    if (paymentMethod == null) return 'Not Set';
    switch (paymentMethod!.toUpperCase()) {
      case 'CASH':
        return 'Cash';
      case 'CARD':
        return 'Card';
      case 'DIGITAL_WALLET':
        return 'Digital Wallet';
      case 'MIXED':
        return 'Mixed Payment';
      default:
        return paymentMethod!;
    }
  }
}

class TopProduct {
  final int id;
  final String name;
  final int totalQuantitySold;
  final double totalRevenue;
  final int numberOfOrders;

  const TopProduct({
    required this.id,
    required this.name,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.numberOfOrders,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      // Backend returns productId from raw SQL; fall back to id
      id: (json['productId'] ?? json['product_id'] ?? json['id'] as num?)?.toInt() ?? 0,
      name: (json['productName'] ?? json['product_name'] ?? json['name']) as String? ?? '',
      totalQuantitySold: (json['totalQuantity'] ?? json['total_quantity_sold'] ?? json['total_qty'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] ?? json['total_revenue'] as num?)?.toDouble() ?? 0,
      numberOfOrders: (json['orderCount'] ?? json['number_of_orders'] ?? json['order_count'] as num?)?.toInt() ?? 0,
    );
  }
}
