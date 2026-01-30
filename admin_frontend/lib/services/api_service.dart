import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_services.dart';

class ApiService {
  static const String baseUrl = "https://relivo-admin-app.onrender.com"; 
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getMe() async {
    final String? token = await _authService.getToken();
    
    if (token == null) {
      throw Exception("User not logged in");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Unauthorized: ${response.body}");
    }
  }
}
