import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'socket_service.dart'; // Import the SocketService

class AuthService {
  // Update this URL based on your setup:
  // For Android Emulator: 'http://10.0.2.2:3000'
  // For iOS Simulator: 'http://localhost:3000' 
  // For Real Device: 'http://YOUR_COMPUTER_IP:3000'
  static const String baseUrl = 'http://192.168.1.50:3000';
  
  static const storage = FlutterSecureStorage();
  static const String tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    return await storage.read(key: tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await storage.write(key: tokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    print("🗑️ Deleting auth token...");
    await storage.delete(key: tokenKey);
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Attempting to register user: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      print('📝 Register response: ${response.statusCode} - ${data.toString()}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
          // Handle socket connection after successful registration
          await SocketService.handleLogin();
        }
        return {
          'success': true,
          'user': data['user'] != null ? User.fromJson(data['user']) : null,
          'token': data['token'],
          'message': data['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Attempting to login user: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      print('🔑 Login response: ${response.statusCode} - ${data.toString()}');

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
          // IMPORTANT: Handle socket reconnection with new token
          await SocketService.handleLogin();
          print('✅ Token saved and socket prepared for new user');
        }
        
        return {
          'success': true,
          'user': data['user'] != null ? User.fromJson(data['user']) : null,
          'token': data['token'],
          'message': data['message'] ?? 'Login successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      print('🚪 Logging out user...');
      
      // 1. IMPORTANT: Disconnect socket before clearing token
      SocketService.handleLogout();
      
      // 2. Clear the token
      await deleteToken();
      
      print('✅ Logout completed successfully');
      
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      print('❌ Logout error: $e');
      return {
        'success': false,
        'message': 'Logout error: $e',
      };
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final isLoggedIn = token != null && token.isNotEmpty;
    print('🔍 Checking login status: $isLoggedIn');
    return isLoggedIn;
  }

  // Method to validate current token with server (optional but recommended)
  static Future<Map<String, dynamic>> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'] != null ? User.fromJson(data['user']) : null,
          'message': 'Token is valid',
        };
      } else {
        // Token is invalid, clear it
        await logout();
        return {
          'success': false,
          'message': data['message'] ?? 'Token validation failed',
        };
      }
    } catch (e) {
      print('❌ Token validation error: $e');
      return {
        'success': false,
        'message': 'Network error during token validation: $e',
      };
    }
  }

  // Method to refresh token (if your backend supports it)
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final currentToken = await getToken();
      if (currentToken == null) {
        return {
          'success': false,
          'message': 'No token to refresh',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        // Reconnect socket with new token
        await SocketService.handleLogin();
        
        return {
          'success': true,
          'token': data['token'],
          'message': 'Token refreshed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Token refresh failed',
        };
      }
    } catch (e) {
      print('❌ Token refresh error: $e');
      return {
        'success': false,
        'message': 'Network error during token refresh: $e',
      };
    }
  }
}