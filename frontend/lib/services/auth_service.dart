import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.100.46:5000';
  static final _secureStorage = const FlutterSecureStorage();
  static String? _accessToken;

  // REGISTER with optional profile picture
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? phone,
    String? shopName,
    XFile? profilePicture,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/register'),
      );

      // Add text fields
      request.fields['username'] = username;
      request.fields['email'] = email;
      request.fields['password'] = password;
      if (phone != null) request.fields['phone'] = phone;
      if (shopName != null) request.fields['shop_name'] = shopName;

      // Add profile picture if provided
      if (profilePicture != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', profilePicture.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _accessToken = data['accessToken'];
        await _secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
        await _secureStorage.write(key: 'user_id', value: data['userId'].toString());
        await _secureStorage.write(key: 'username', value: data['username']);
        
        // Store profile picture URL
        if (data['profile_picture'] != null) {
          await _secureStorage.write(key: 'profile_picture', value: data['profile_picture']);
        }
        
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _accessToken = data['accessToken'];
        await _secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
        await _secureStorage.write(key: 'user_id', value: data['userId'].toString());
        await _secureStorage.write(key: 'username', value: data['username']);
        
        // Fetch user profile to get profile picture
        final userId = data['userId'].toString();
        final userProfile = await getUserById(userId);
        if (userProfile['success'] == true && userProfile['data']['profile_picture'] != null) {
          await _secureStorage.write(key: 'profile_picture', value: userProfile['data']['profile_picture']);
        }
        
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // REFRESH ACCESS TOKEN (with token rotation)
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        // Store new refresh token (token rotation)
        await _secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
        return true;
      } else {
        // Refresh token expired or invalid - logout user
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        // Call backend to invalidate refresh token
        await http.post(
          Uri.parse('$baseUrl/api/users/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      }
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      _accessToken = null;
      await _secureStorage.deleteAll();
    }
  }

  // AUTHENTICATED REQUEST HELPER
  static Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    headers ??= {};
    headers['Content-Type'] = 'application/json';
    
    // Add access token to headers
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    http.Response response;
    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If access token expired, refresh and retry
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        // Retry request with new access token
        headers['Authorization'] = 'Bearer $_accessToken';
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
          case 'POST':
            response = await http.post(uri, headers: headers, body: jsonEncode(body));
            break;
          case 'PUT':
            response = await http.put(uri, headers: headers, body: jsonEncode(body));
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: headers);
            break;
        }
      }
    }

    return response;
  }

  // UPDATE PROFILE
 static Future<Map<String, dynamic>> updateProfile({
  String? username,
  String? phone,
  String? shopName,
  XFile? profilePicture,
}) async {
  try {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/api/users/update-profile'),
    );

    // Add authorization header
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Add text fields if provided
    if (username != null) request.fields['username'] = username;
    if (phone != null) request.fields['phone'] = phone;
    if (shopName != null) request.fields['shop_name'] = shopName;

    // Add profile picture if provided
    if (profilePicture != null) {
      var multipartFile = await http.MultipartFile.fromPath(
        'image', 
        profilePicture.path,
      );
      request.files.add(multipartFile);
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // Handle token expiration
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        // CREATE A COMPLETELY NEW REQUEST - don't reuse the old one
        var retryRequest = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/api/users/update-profile'),
        );
        
        retryRequest.headers['Authorization'] = 'Bearer $_accessToken';
        
        if (username != null) retryRequest.fields['username'] = username;
        if (phone != null) retryRequest.fields['phone'] = phone;
        if (shopName != null) retryRequest.fields['shop_name'] = shopName;
        
        if (profilePicture != null) {
          var multipartFile = await http.MultipartFile.fromPath(
            'image', 
            profilePicture.path,
          );
          retryRequest.files.add(multipartFile);
        }
        
        streamedResponse = await retryRequest.send();
        response = await http.Response.fromStream(streamedResponse);
      }
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (username != null) {
        await _secureStorage.write(key: 'username', value: username);
      }
      if (data['profile_picture'] != null) {
        await _secureStorage.write(key: 'profile_picture', value: data['profile_picture']);
      }
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Update failed'};
    }
  } catch (e) {
    print('Update profile error: $e'); // Debug log
    return {'success': false, 'message': 'Network error: $e'};
  }
}

  // GET USER BY ID
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to get user'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GETTERS
  static String? getAccessToken() => _accessToken;

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  static Future<bool> isLoggedIn() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null;
  }

  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  static Future<String?> getUsername() async {
    return await _secureStorage.read(key: 'username');
  }

  // Add getter for profile picture
  static Future<String?> getProfilePicture() async {
    return await _secureStorage.read(key: 'profile_picture');
  }
}