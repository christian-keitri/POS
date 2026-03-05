class SalesReport {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final double totalSubtotal;
  final double totalTax;
  final double totalDiscounts;
  final List<DailyBreakdown> dailyBreakdown;
  final List<PaymentMethodSummary> paymentMethods;

  const SalesReport({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalSubtotal,
    required this.totalTax,
    required this.totalDiscounts,
    this.dailyBreakdown = const [],
    this.paymentMethods = const [],
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    final dailyList = json['daily_breakdown'] as List<dynamic>?;
    final paymentList = json['payment_methods'] as List<dynamic>?;

    return SalesReport(
      totalOrders: (summary['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (summary['total_revenue'] as num?)?.toDouble() ?? 0,
      averageOrderValue: (summary['average_order_value'] as num?)?.toDouble() ?? 0,
      totalSubtotal: (summary['total_subtotal'] as num?)?.toDouble() ?? 0,
      totalTax: (summary['total_tax'] as num?)?.toDouble() ?? 0,
      totalDiscounts: (summary['total_discounts'] as num?)?.toDouble() ?? 0,
      dailyBreakdown: dailyList?.map((e) => DailyBreakdown.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      paymentMethods: paymentList?.map((e) => PaymentMethodSummary.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class DailyBreakdown {
  final String date;
  final int ordersCount;
  final double revenue;

  const DailyBreakdown({
    required this.date,
    required this.ordersCount,
    required this.revenue,
  });

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: json['date'] as String,
      ordersCount: (json['orders_count'] as num).toInt(),
      revenue: (json['revenue'] as num).toDouble(),
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
      paymentMethod: json['payment_method'] as String?,
      count: (json['count'] as num).toInt(),
      total: (json['total'] as num).toDouble(),
    );
  }

  String get methodDisplay {
    if (paymentMethod == null) return 'Not Set';
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'digital_wallet':
        return 'Digital Wallet';
      case 'mixed':
        return 'Mixed Payment';
      default:
        return paymentMethod!;
    }
  }
}

class TopProduct {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final String? categoryName;
  final int totalQuantitySold;
  final double totalRevenue;
  final int numberOfOrders;

  const TopProduct({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.categoryName,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.numberOfOrders,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      categoryName: json['category_name'] as String?,
      totalQuantitySold: (json['total_quantity_sold'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      numberOfOrders: (json['number_of_orders'] as num).toInt(),
    );
  }
}
