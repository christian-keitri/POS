import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pos/config/api_config.dart';
import 'package:pos/models/category.dart';
import 'package:pos/models/order.dart';
import 'package:pos/models/product.dart';

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
        'description': ?description,
        'sort_order': ?sortOrder,
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
        'description': ?description,
        'sort_order': ?sortOrder,
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
}
