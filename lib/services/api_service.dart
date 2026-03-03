import 'dart:convert';
import 'package:http/http.dart' as http;
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

  static Future<Category> createCategory(String name) async {
    final r = await http.post(
      Uri.parse('$_base/api/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (r.statusCode != 201) {
      final err = jsonDecode(r.body);
      throw Exception(err['error'] ?? r.body);
    }
    return Category.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<void> updateCategory(int id, String name) async {
    final r = await http.put(
      Uri.parse('$_base/api/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
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

  static Future<List<Product>> getProducts({int? categoryId}) async {
    var url = '$_base/api/products';
    if (categoryId != null) url += '?category_id=$categoryId';
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
    required double price,
    double? cost,
    int? stock,
    int? categoryId,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/api/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'sku': sku,
        'price': price,
        'cost': cost,
        'stock': stock,
        'category_id': categoryId,
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
    double? price,
    double? cost,
    int? stock,
    int? categoryId,
  }) async {
    final r = await http.put(
      Uri.parse('$_base/api/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null) 'name': name,
        if (sku != null) 'sku': sku,
        if (price != null) 'price': price,
        if (cost != null) 'cost': cost,
        if (stock != null) 'stock': stock,
        if (categoryId != null) 'category_id': categoryId,
      }),
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
      final body = r.body.isEmpty ? {} : jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? r.body);
    }
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

  static Future<Order> createOrder({
    int? userId,
    required List<Map<String, dynamic>> items,
  }) async {
    final r = await http.post(
      Uri.parse('$_base/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'items': items,
      }),
    );
    if (r.statusCode != 201) {
      final err = jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? r.body);
    }
    return Order.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<Order> updateOrderStatus(int id, String status) async {
    final r = await http.patch(
      Uri.parse('$_base/api/orders/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (r.statusCode != 200) {
      final err = jsonDecode(r.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? r.body);
    }
    return Order.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }
}
