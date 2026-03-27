import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class ShopService {
  static const String baseUrl = 'http://192.168.100.46:5000';

  // CREATE SHOP
  static Future<Map<String, dynamic>> createShop({
    required String shopName,
    XFile? shopImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/shops/createShop'),
      );
 
      // Add authorization header
      final accessToken = AuthService.getAccessToken();
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Add shop name
      request.fields['shop_name'] = shopName;

      // Add shop image if provided
      if (shopImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', shopImage.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Handle token expiration
      if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          request.headers['Authorization'] = 'Bearer ${AuthService.getAccessToken()}';
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create shop'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

// UPDATE SHOP
static Future<Map<String, dynamic>> updateShop({
  String? shopName,
  XFile? shopImage,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/shops/updateShop'),
    );

    // Add authorization header
    final accessToken = AuthService.getAccessToken();
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Add shop name if provided
    if (shopName != null) {
      request.fields['shop_name'] = shopName;
    }

    // Add shop image if provided
    if (shopImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', shopImage.path),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // Handle token expiration
    if (response.statusCode == 401) {
      final refreshed = await AuthService.refreshAccessToken();
      if (refreshed) {
        // CREATE NEW REQUEST with all fields and files
        var retryRequest = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/shops/updateShop'),
        );
        
        retryRequest.headers['Authorization'] = 'Bearer ${AuthService.getAccessToken()}';
        
        // Re-add shop name if provided
        if (shopName != null) {
          retryRequest.fields['shop_name'] = shopName;
        }
        
        // Re-add shop image if provided
        if (shopImage != null) {
          retryRequest.files.add(
            await http.MultipartFile.fromPath('image', shopImage.path),
          );
        }
        
        streamedResponse = await retryRequest.send();
        response = await http.Response.fromStream(streamedResponse);
      }
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Failed to update shop'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}

  // DELETE SHOP
  static Future<Map<String, dynamic>> deleteShop() async {
    try {
      final response = await AuthService.authenticatedRequest(
        method: 'DELETE',
        endpoint: '/api/shops/deleteShop',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete shop'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET USER SHOP INFO (from user profile)
  static Future<Map<String, dynamic>> getUserShopInfo() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userInfo = await AuthService.getUserById(userId);
      if (userInfo['success'] == true) {
        final userData = userInfo['data'];
        return {
          'success': true,
          'hasShop': userData['has_shop'] == 1,
          'shopName': userData['shop_name'],
          'shopPicture': userData['shop_picture'],
        };
      } else {
        return {'success': false, 'message': 'Failed to get user info'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}