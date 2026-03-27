import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  static const String baseUrl = 'http://192.168.100.46:5000';

  // ADD TO CART
  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'POST',
        endpoint: '/api/orders/add-to-cart',
        body: {
          'product_id': productId,
          'quantity': quantity,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to add to cart'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET CART ITEMS
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'GET',
        endpoint: '/api/orders/getOrders',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'cartItems': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch cart'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET CART TOTAL
  static Future<Map<String, dynamic>> getCartTotal() async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'GET',
        endpoint: '/api/orders/getCartTotal',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cartItems': data['cartItems'],
          'cartTotal': data['cartTotal'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch cart total'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // UPDATE CART ITEM
  static Future<Map<String, dynamic>> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'PUT',
        endpoint: '/api/orders/updateCartItem',
        body: {
          'cart_id': cartId,
          'quantity': quantity,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update cart'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // DELETE CART ITEM - FIXED to use POST instead of DELETE
  static Future<Map<String, dynamic>> deleteCartItem(String cartId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'POST',  // Changed from DELETE to POST
        endpoint: '/api/orders/removeFromCart',
        body: {'cart_id': cartId},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete item'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET USER ORDERS
  static Future<Map<String, dynamic>> getUserOrders() async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'GET',
        endpoint: '/api/orders/my-orders',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': data['orders'] ?? [],
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch orders'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // BUY PRODUCTS (Checkout selected items)
  static Future<Map<String, dynamic>> buyProducts({
    required List<String> cartIds,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'POST',
        endpoint: '/api/orders/buyProduct',
        body: {
          'cart_ids': cartIds,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'orderId': data['orderId'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to complete purchase'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}