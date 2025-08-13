import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  // Update this URL based on your setup:
  // For Android Emulator: 'http://10.0.2.2:3000'
  // For iOS Simulator: 'http://localhost:3000'
  // For Real Device: 'http://YOUR_COMPUTER_IP:3000'
  static const String baseUrl = 'http://192.168.1.50:3000';

  static Future<List<User>> getUsers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((userData) => User.fromJson(userData)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}