import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/models/category.dart';
import 'package:pos/models/order.dart';
import 'package:pos/models/product.dart';
import 'package:pos/models/user.dart';
import 'package:pos/models/stock_adjustment.dart';
import 'package:pos/models/reports.dart';

class ApiService {
  static const _base = apiBaseUrl;

  static Future<List<Category>> getCategories() async {
    final r = await http.get(Uri.parse('$_base/api/categories'));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Category> createCategory(String name, {String? description, int? sortOrder}) async {
    final r = await http.post(
      Uri.parse('$_base/api/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'sort_order': sortOrder,
      }),
    );
    if (r.statusCode != 201) {
      final err = jsonDecode(r.body);
      throw Exception(err['error'] ?? r.body);
    }
    return Category.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<void> updateCategory(int id, String name, {String? description, int? sortOrder}) async {
    final r = await http.put(
      Uri.parse('$_base/api/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'sort_order': sortOrder,
      }),
    );
    if (r.statusCode != 200) {
      final err = jsonDecode(r.body);
      throw Exception(err['error'] ?? r.body);
    }
  }

  static Future<void> deleteCategory(int id) async {
    final r = await http.delete(Uri.parse('$_base/api/categories/$id'));
    if (r.statusCode != 204) {
      final body = r.body.isEmpty ? {} : jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? r.body);
    }
  }

  static Future<List<Product>> getProducts({int? categoryId, bool activeOnly = false}) async {
    var url = '$_base/api/products';
    final q = <String>[];
    if (categoryId != null) q.add('category_id=$categoryId');
    if (activeOnly) q.add('active_only=1');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Product> getProduct(int id) async {
    final r = await http.get(Uri.parse('$_base/api/products/$id'));
    if (r.statusCode != 200) throw Exception(r.body);
    return Product.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Product> createProduct({
    required String name,
    String? sku,
    String? barcode,
    String? description,
    required double price,
    double? cost,
    int? stock,
    int? categoryId,
    bool isActive = true,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/api/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'description': description,
        'price': price,
        'cost': cost,
        'stock': stock,
        'category_id': categoryId,
        'is_active': isActive,
      }),
    );
    if (r.statusCode != 201) {
      final err = jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? r.body);
    }
    return Product.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Product> updateProduct(
    int id, {
    String? name,
    String? sku,
    String? barcode,
    String? description,
    double? price,
    double? cost,
    int? stock,
    int? categoryId,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (sku != null) body['sku'] = sku;
    if (barcode != null) body['barcode'] = barcode;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (cost != null) body['cost'] = cost;
    if (stock != null) body['stock'] = stock;
    if (categoryId != null) body['category_id'] = categoryId;
    if (isActive != null) body['is_active'] = isActive;
    final r = await http.put(
      Uri.parse('$_base/api/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      final err = jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? r.body);
    }
    return Product.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<void> deleteProduct(int id) async {
    final r = await http.delete(Uri.parse('$_base/api/products/$id'));
    if (r.statusCode != 204) {
      String msg = r.body;
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body.containsKey('error')) msg = body['error'] as String;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Upload product image (JPEG/PNG/GIF/WebP, max 5MB). Call after create/update product.
  static Future<Product> uploadProductImage(int productId, File imageFile) async {
    if (!imageFile.existsSync()) throw Exception('Image file not found');
    final bytes = await imageFile.readAsBytes();
    final uri = Uri.parse('$_base/api/products/$productId/image');
    final request = http.MultipartRequest('POST', uri);
    final ext = imageFile.path.toLowerCase().split('.').last;
    final isPng = ext == 'png';
    final isGif = ext == 'gif';
    final isWebp = ext == 'webp';
    final mime = isPng ? 'image/png' : isGif ? 'image/gif' : isWebp ? 'image/webp' : 'image/jpeg';
    final name = 'image.${ext == 'jpg' || ext == 'jpeg' || isPng || isGif || isWebp ? ext : 'jpg'}';
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: name,
      contentType: MediaType.parse(mime),
    ));
    final streamed = await request.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode != 200) {
      String msg = r.body;
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is Map && decoded.containsKey('error')) msg = decoded['error'] as String;
      } catch (_) {}
      throw Exception(msg);
    }
    return Product.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getOrderStats({int? userId}) async {
    var url = '$_base/api/orders/stats';
    if (userId != null) url += '?user_id=$userId';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<List<Order>> getOrders({int? userId, String? status}) async {
    var url = '$_base/api/orders';
    final q = <String>[];
    if (userId != null) q.add('user_id=$userId');
    if (status != null) q.add('status=$status');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Order> getOrder(int id) async {
    final r = await http.get(Uri.parse('$_base/api/orders/$id'));
    if (r.statusCode != 200) throw Exception(r.body);
    return Order.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static int _itemInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Future<Order> createOrder({
    int? userId,
    int? cashierId,
    String? paymentMethod,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'cashier_id': cashierId,
        'payment_method': paymentMethod,
        'notes': notes,
        'items': items
            .map((e) => {
                  'product_id': _itemInt(e['product_id']),
                  'quantity': _itemInt(e['quantity']).clamp(1, 999999),
                })
            .toList(),
      }),
    );
    if (r.statusCode != 201) {
      String message = r.body;
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is Map && decoded.containsKey('error')) {
          message = decoded['error'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }
    return Order.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Order> updateOrderStatus(int id, String status) async {
    return updateOrder(id, status: status);
  }

  static Future<Order> updateOrder(
    int id, {
    String? status,
    String? paymentMethod,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (notes != null) body['notes'] = notes;
    if (body.isEmpty) throw Exception('Provide at least one of: status, payment_method, notes');
    final r = await http.patch(
      Uri.parse('$_base/api/orders/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      final err = jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? r.body);
    }
    return Order.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getReceipt(int orderId) async {
    final r = await http.get(Uri.parse('$_base/api/orders/$orderId/receipt'));
    if (r.statusCode != 200) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // ==================== User Management ====================

  static Future<List<User>> getUsers({String? role, bool? isActive}) async {
    var url = '$_base/api/auth/users';
    final q = <String>[];
    if (role != null) q.add('role=$role');
    if (isActive != null) q.add('is_active=${isActive ? '1' : '0'}');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<User> getUser(int id) async {
    final r = await http.get(Uri.parse('$_base/api/auth/users/$id'));
    if (r.statusCode != 200) throw Exception(r.body);
    return User.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<User> createUser({
    required String email,
    required String password,
    String? businessName,
    String? displayName,
    String role = 'cashier',
  }) async {
    final r = await http.post(
      Uri.parse('$_base/api/auth/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'business_name': businessName,
        'display_name': displayName,
        'role': role,
      }),
    );
    if (r.statusCode != 201) {
      final err = jsonDecode(r.body);
      throw Exception(err['error'] ?? r.body);
    }
    return User.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<User> updateUser(
    int id, {
    String? email,
    String? password,
    String? businessName,
    String? displayName,
    String? role,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (businessName != null) body['business_name'] = businessName;
    if (displayName != null) body['display_name'] = displayName;
    if (role != null) body['role'] = role;
    if (isActive != null) body['is_active'] = isActive;
    final r = await http.put(
      Uri.parse('$_base/api/auth/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      final err = jsonDecode(r.body);
      throw Exception(err['error'] ?? r.body);
    }
    return User.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<void> deleteUser(int id) async {
    final r = await http.delete(Uri.parse('$_base/api/auth/users/$id'));
    if (r.statusCode != 204) {
      final body = r.body.isEmpty ? {} : jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? r.body);
    }
  }

  // ==================== Stock Management ====================

  static Future<List<StockAdjustment>> getStockAdjustments({
    int? productId,
    int? userId,
    String? reason,
    int limit = 100,
    int offset = 0,
  }) async {
    var url = '$_base/api/stock/adjustments';
    final q = <String>[];
    if (productId != null) q.add('product_id=$productId');
    if (userId != null) q.add('user_id=$userId');
    if (reason != null) q.add('reason=$reason');
    q.add('limit=$limit');
    q.add('offset=$offset');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => StockAdjustment.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<StockAdjustment> adjustStock({
    required int productId,
    int? userId,
    required int quantityChange,
    String reason = 'adjustment',
    String? notes,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/api/stock/adjust'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'product_id': productId,
        'user_id': userId,
        'quantity_change': quantityChange,
        'reason': reason,
        'notes': notes,
      }),
    );
    if (r.statusCode != 201) {
      final err = jsonDecode(r.body);
      throw Exception(err['error'] ?? r.body);
    }
    return StockAdjustment.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<List<Product>> getLowStockAlerts({int? categoryId}) async {
    var url = '$_base/api/stock/alerts';
    if (categoryId != null) url += '?category_id=$categoryId';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ==================== Reports ====================

  static Future<SalesReport> getSalesReport({
    String period = 'daily',
    String? startDate,
    String? endDate,
    int? cashierId,
    String status = 'completed',
  }) async {
    var url = '$_base/api/reports/sales';
    final q = <String>[];
    q.add('period=$period');
    if (startDate != null) q.add('start_date=$startDate');
    if (endDate != null) q.add('end_date=$endDate');
    if (cashierId != null) q.add('cashier_id=$cashierId');
    q.add('status=$status');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    return SalesReport.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getInventoryReport({
    int? categoryId,
    bool lowStockOnly = false,
  }) async {
    var url = '$_base/api/reports/inventory';
    final q = <String>[];
    if (categoryId != null) q.add('category_id=$categoryId');
    if (lowStockOnly) q.add('low_stock_only=1');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<List<TopProduct>> getTopProducts({
    String period = 'monthly',
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    var url = '$_base/api/reports/top-products';
    final q = <String>[];
    q.add('period=$period');
    q.add('limit=$limit');
    if (startDate != null) q.add('start_date=$startDate');
    if (endDate != null) q.add('end_date=$endDate');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    final list = jsonDecode(r.body) as List;
    return list.map((e) => TopProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Map<String, dynamic>>> getUserActivityLogs({
    int? userId,
    String? action,
    String? startDate,
    String? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    var url = '$_base/api/reports/user-activity';
    final q = <String>[];
    if (userId != null) q.add('user_id=$userId');
    if (action != null) q.add('action=$action');
    if (startDate != null) q.add('start_date=$startDate');
    if (endDate != null) q.add('end_date=$endDate');
    q.add('limit=$limit');
    q.add('offset=$offset');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getRevenueAnalytics({
    String period = 'daily',
    int days = 30,
  }) async {
    var url = '$_base/api/reports/revenue?period=$period&days=$days';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getCashierPerformance({
    String period = 'monthly',
    String? startDate,
    String? endDate,
  }) async {
    var url = '$_base/api/reports/cashier-performance';
    final q = <String>[];
    q.add('period=$period');
    if (startDate != null) q.add('start_date=$startDate');
    if (endDate != null) q.add('end_date=$endDate');
    if (q.isNotEmpty) url += '?${q.join('&')}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception(r.body);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }
}

