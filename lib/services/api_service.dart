import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'https://dummyjson.com/products';

  // Get list of products (default limit 30, which fulfills >= 10 products)
  static Future<List<ProductModel>> getProducts({
    int limit = 30,
    int skip = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl?limit=$limit&skip=$skip');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> productsJson =
            data['products'] as List<dynamic>? ?? [];
        return productsJson
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal memuat produk (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Gagal memuat')) {
        rethrow;
      }
      throw Exception(
        'Gagal terhubung ke server DummyJSON. Periksa koneksi internet Anda.',
      );
    }
  }

  // Get detail of a single product: GET /products/{id}
  static Future<ProductModel> getProductDetail(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ProductModel.fromJson(data);
      } else {
        throw Exception(
          'Gagal memuat detail produk (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Gagal memuat')) {
        rethrow;
      }
      throw Exception(
        'Gagal terhubung ke server DummyJSON. Periksa koneksi internet Anda.',
      );
    }
  }

  // Get all categories: GET /products/category-list
  static Future<List<String>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/category-list');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception(
          'Gagal memuat daftar kategori (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Gagal memuat')) {
        rethrow;
      }
      throw Exception(
        'Gagal memuat kategori dari server DummyJSON.',
      );
    }
  }

  // Get products by specific category: GET /products/category/{category}
  static Future<List<ProductModel>> getProductsByCategory(
    String category,
  ) async {
    try {
      final encodedCategory = Uri.encodeComponent(category.trim());
      final uri = Uri.parse('$baseUrl/category/$encodedCategory');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> productsJson =
            data['products'] as List<dynamic>? ?? [];
        return productsJson
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal memuat produk kategori $category (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Gagal memuat')) {
        rethrow;
      }
      throw Exception(
        'Gagal terhubung ke server DummyJSON.',
      );
    }
  }

  // Search products by name/query: GET /products/search?q={query}
  static Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final uri = Uri.parse('$baseUrl/search?q=$encodedQuery');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> productsJson =
            data['products'] as List<dynamic>? ?? [];
        return productsJson
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal mencari produk (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Gagal mencari')) {
        rethrow;
      }
      throw Exception(
        'Gagal terhubung ke server DummyJSON.',
      );
    }
  }
}
