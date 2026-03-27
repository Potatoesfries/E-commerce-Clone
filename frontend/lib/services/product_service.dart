import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class ProductService {
  static const String baseUrl = 'http://192.168.100.46:5000';

  // CREATE PRODUCT
  static Future<Map<String, dynamic>> createProduct({
    required String productName,
    required double price,
    required String category,
    String? description,
    int? stock,
    required XFile productImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/products/create'),
      );

      final accessToken = AuthService.getAccessToken();
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      request.fields['product_name'] = productName;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      if (description != null) request.fields['description'] = description;
      if (stock != null) request.fields['stock'] = stock.toString();

      request.files.add(
        await http.MultipartFile.fromPath('product_image', productImage.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          request.headers['Authorization'] = 'Bearer ${AuthService.getAccessToken()}';
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET MY PRODUCTS
  static Future<Map<String, dynamic>> getMyProducts() async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'GET',
        endpoint: '/api/products/my-products',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'products': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch products'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET ALL PRODUCTS
  static Future<Map<String, dynamic>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/all'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'products': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch products'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET PRODUCTS BY CATEGORY
  static Future<Map<String, dynamic>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/category/$category'),
      );

      if (response.statusCode == 200) {
        final products = jsonDecode(response.body) as List;
        return {'success': true, 'products': products};
      } else {
        return {'success': false, 'message': 'Failed to load products'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // GET PRODUCT BY ID
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'product': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // UPDATE PRODUCT
  static Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? productName,
    double? price,
    String? category,
    String? description,
    int? stock,
    XFile? productImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/products/update/$productId'),
      );

      final accessToken = AuthService.getAccessToken();
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      if (productName != null) request.fields['product_name'] = productName;
      if (price != null) request.fields['price'] = price.toString();
      if (category != null) request.fields['category'] = category;
      if (description != null) request.fields['description'] = description;
      if (stock != null) request.fields['stock'] = stock.toString();

      if (productImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('product_image', productImage.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          request.headers['Authorization'] = 'Bearer ${AuthService.getAccessToken()}';
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // DELETE PRODUCT
  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'DELETE',
        endpoint: '/api/products/delete/$productId',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete product'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}